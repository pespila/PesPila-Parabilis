"""Data pipeline orchestrator."""

from __future__ import annotations

import csv
import json
import logging
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
import polars as pl

from pespila.data.db import DatabaseManager
from pespila.data.registry import (
    LEAGUE_REGISTRY,
    LeagueInfo,
    get_all_seasons,
    season_label,
    season_years,
)
from pespila.data.scraper import FootballDataScraper

logger = logging.getLogger(__name__)


def _parse_date(date_str: str) -> str | None:
    """Parse date string handling DD/MM/YY and DD/MM/YYYY formats."""
    if not date_str or date_str.strip() == "":
        return None
    date_str = date_str.strip()
    for fmt in ("%d/%m/%Y", "%d/%m/%y", "%Y-%m-%d"):
        try:
            return datetime.strptime(date_str, fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    return None


def _safe_int(val: str | None) -> int | None:
    if val is None or val == "" or val == "null":
        return None
    try:
        return int(float(val))
    except (ValueError, TypeError):
        return None


def _safe_float(val: str | None) -> float | None:
    if val is None or val == "" or val == "null":
        return None
    try:
        return float(val)
    except (ValueError, TypeError):
        return None


class DataPipeline:
    """Orchestrates data download, parsing, and database population."""

    def __init__(self, db_path: str | Path = "data/pespila.db") -> None:
        self.db_path = Path(db_path)
        self.scraper = FootballDataScraper()

    def full_refresh(self, countries: list[str] | None = None) -> None:
        """Download all historical data, create schema, populate tables."""
        logger.info("Starting full data refresh...")

        with DatabaseManager(self.db_path) as db:
            db.create_schema()
            self._seed_seasons(db)

        raw_data = self.scraper.scrape_all_sync(countries=countries)
        logger.info("Downloaded %d league/season CSVs", len(raw_data))

        with DatabaseManager(self.db_path) as db:
            for league_info, season_code, df in raw_data:
                self._ingest_csv(db, league_info, season_code, df)

        logger.info("Full refresh complete.")

    # Columns we extract from football-data.co.uk CSVs — everything else is ignored.
    _CSV_COLUMNS = [
        "Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG", "FTR",
        "HTHG", "HTAG", "HTR", "B365H", "B365D", "B365A",
    ]

    def from_local(self, csv_dir: str | Path, compute_matchdays: bool = True) -> None:
        """Ingest CSVs from a local directory of football-data.co.uk files.

        Supports two layouts:
        - Flat:   <csv_dir>/<season>_<league>.csv  (e.g. csvs/2324_D1.csv)
        - Nested: <csv_dir>/<season>/<league>.csv   (e.g. csvs/2324/D1.csv)

        Handles ragged rows, trailing commas, BOM markers, variable column
        counts across eras, and silently skips non-CSV files (e.g. Cloudflare
        HTML blocks).
        """
        csv_dir = Path(csv_dir)
        if not csv_dir.is_dir():
            raise FileNotFoundError(f"Directory not found: {csv_dir}")

        league_map = {lg.league_code: lg for lg in LEAGUE_REGISTRY}

        # Collect (csv_path, season_code, league_code) from both layouts
        entries: list[tuple[Path, str, str]] = []

        # Flat: <season>_<league>.csv
        for csv_file in csv_dir.glob("*.csv"):
            parts = csv_file.stem.split("_", 1)
            if len(parts) == 2:
                entries.append((csv_file, parts[0], parts[1]))

        # Nested: <season>/<league>.csv
        for csv_file in csv_dir.glob("*/*.csv"):
            entries.append((csv_file, csv_file.parent.name, csv_file.stem))

        entries.sort(key=lambda e: e[0].name)

        if not entries:
            logger.warning("No CSVs found in %s", csv_dir)
            return

        logger.info("Found %d CSV files in %s", len(entries), csv_dir)

        with DatabaseManager(self.db_path) as db:
            db.create_schema()
            self._seed_seasons(db)

        with DatabaseManager(self.db_path) as db:
            ingested = 0
            skipped_html = 0
            skipped_empty = 0
            for csv_file, season_code, league_code in entries:
                league_info = league_map.get(league_code)
                if not league_info:
                    logger.debug("Skipping unknown league code: %s", league_code)
                    continue

                df = self._read_local_csv(csv_file)
                if df is None:
                    skipped_html += 1
                    continue
                if len(df) == 0:
                    skipped_empty += 1
                    continue

                self._ingest_csv(db, league_info, season_code, df)
                ingested += 1

        logger.info(
            "Ingested %d CSV files from %s (skipped %d HTML, %d empty)",
            ingested, csv_dir, skipped_html, skipped_empty,
        )

        if compute_matchdays:
            self.compute_all_matchdays()

    def _read_local_csv(self, csv_file: Path) -> pl.DataFrame | None:
        """Read a single football-data.co.uk CSV into a polars DataFrame.

        Returns None if the file is not a valid CSV (e.g. HTML).
        Returns an empty DataFrame if the file has no usable match rows.
        Uses Python csv.DictReader for maximum tolerance of ragged rows,
        trailing commas, BOM markers, and inconsistent column counts.
        """
        # Quick sniff: skip HTML / non-CSV content
        try:
            with open(csv_file, "rb") as f:
                raw = f.read(1024)
        except OSError:
            return None
        # Strip BOM for the sniff check
        text_start = raw.lstrip(b"\xef\xbb\xbf").lstrip()
        if text_start.startswith(b"<") or text_start.startswith(b"<!"):
            logger.debug("Skipping HTML file: %s", csv_file.name)
            return None

        rows: list[dict[str, str]] = []
        with open(csv_file, encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f, restval="")
            if reader.fieldnames is None:
                return pl.DataFrame()

            # Strip whitespace / BOM from header names
            reader.fieldnames = [h.strip().strip("\ufeff") for h in reader.fieldnames]

            # Map available columns to the ones we need
            available = set(reader.fieldnames)
            target_cols = [c for c in self._CSV_COLUMNS if c in available]

            if "HomeTeam" not in available or "AwayTeam" not in available:
                logger.debug("Skipping file without HomeTeam/AwayTeam: %s", csv_file.name)
                return pl.DataFrame()

            for row in reader:
                # Extract only the columns we care about, default to ""
                rows.append({col: (row.get(col) or "").strip() for col in target_cols})

        if not rows:
            return pl.DataFrame()

        # All columns as Utf8 — type conversion happens downstream in _ingest_csv
        schema = {col: pl.Utf8 for col in target_cols}
        return pl.DataFrame(rows, schema=schema)

    def _seed_seasons(self, db: DatabaseManager) -> None:
        """Pre-populate all season records."""
        for code in get_all_seasons():
            lbl = season_label(code)
            ys, ye = season_years(code)
            db.get_or_create_season(lbl, ys, ye)

    def _ingest_csv(
        self,
        db: DatabaseManager,
        league_info: LeagueInfo,
        season_code: str,
        df: pl.DataFrame,
    ) -> None:
        """Ingest a single CSV DataFrame into the database."""
        country_id = db.get_or_create_country(league_info.country, league_info.country_code)

        league_id = db.get_or_create_league(
            country_id, league_info.league_name, league_info.league_code, league_info.tier
        )

        lbl = season_label(season_code)
        ys, ye = season_years(season_code)
        season_id = db.get_or_create_season(lbl, ys, ye)

        cols = set(df.columns)
        rows_to_insert: list[tuple] = []

        for row in df.iter_rows(named=True):
            home_name = (row.get("HomeTeam") or "").strip()
            away_name = (row.get("AwayTeam") or "").strip()
            if not home_name or not away_name:
                continue

            home_id = db.get_or_create_team(home_name)
            away_id = db.get_or_create_team(away_name)

            date_str = row.get("Date", "")
            match_date = _parse_date(str(date_str)) if date_str else None

            fthg = _safe_int(row.get("FTHG"))
            ftag = _safe_int(row.get("FTAG"))
            ftr = (row.get("FTR") or "").strip() or None
            hthg = _safe_int(row.get("HTHG")) if "HTHG" in cols else None
            htag = _safe_int(row.get("HTAG")) if "HTAG" in cols else None
            htr = (row.get("HTR") or "").strip() or None if "HTR" in cols else None

            b365h = _safe_float(row.get("B365H")) if "B365H" in cols else None
            b365d = _safe_float(row.get("B365D")) if "B365D" in cols else None
            b365a = _safe_float(row.get("B365A")) if "B365A" in cols else None

            rows_to_insert.append((
                league_id, season_id, match_date, home_id, away_id,
                fthg, ftag, ftr, hthg, htag, htr,
                b365h, b365d, b365a,
            ))

        if rows_to_insert:
            db.executemany(
                """INSERT OR IGNORE INTO matches
                   (league_id, season_id, match_date, home_team_id, away_team_id,
                    fthg, ftag, ftr, hthg, htag, htr, b365h, b365d, b365a)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                rows_to_insert,
            )
            db.commit()
            logger.info(
                "Ingested %d matches for %s %s",
                len(rows_to_insert),
                league_info.league_code,
                season_code,
            )

    def compute_distributions(self, league_id: int, season_id: int) -> None:
        """Compute goal distributions for all teams in a league/season."""
        from pespila.distributions import DistributionSelector

        selector = DistributionSelector()

        with DatabaseManager(self.db_path) as db:
            # Get all teams that played in this league/season
            teams = db.fetchall(
                """SELECT DISTINCT t.team_id, t.name FROM teams t
                   JOIN matches m ON t.team_id = m.home_team_id OR t.team_id = m.away_team_id
                   WHERE m.league_id = ? AND m.season_id = ?""",
                (league_id, season_id),
            )

            for team_row in teams:
                team_id = team_row["team_id"]
                for perspective in ("scored", "conceded"):
                    freqs = self._get_goal_frequencies(db, team_id, league_id, season_id, perspective)
                    if np.sum(freqs) == 0:
                        continue

                    best = selector.select(freqs)
                    db.execute(
                        """INSERT OR REPLACE INTO goal_distributions
                           (team_id, season_id, league_id, perspective,
                            freq_0, freq_1, freq_2, freq_3, freq_4, freq_5plus,
                            best_dist, best_pvalue, params_json)
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                        (
                            team_id, season_id, league_id, perspective,
                            int(freqs[0]), int(freqs[1]), int(freqs[2]),
                            int(freqs[3]), int(freqs[4]), int(freqs[5]),
                            best.name, best.p_value_,
                            json.dumps(best.params_),
                        ),
                    )
            db.commit()

    def _get_goal_frequencies(
        self,
        db: DatabaseManager,
        team_id: int,
        league_id: int,
        season_id: int,
        perspective: str,
    ) -> np.ndarray:
        """Get goal frequency vector [f0, f1, f2, f3, f4, f5+] for a team.

        For 'scored': count goals the team scored (home FTHG + away FTAG).
        For 'conceded': count goals the team conceded (home FTAG + away FTHG).
        """
        freqs = np.zeros(6, dtype=np.int64)

        if perspective == "scored":
            home_col, away_col = "fthg", "ftag"
        else:  # conceded
            home_col, away_col = "ftag", "fthg"

        # Home matches
        home_goals = db.fetchall(
            f"""SELECT {home_col} as goals FROM matches
                WHERE home_team_id = ? AND league_id = ? AND season_id = ?
                AND {home_col} IS NOT NULL""",
            (team_id, league_id, season_id),
        )
        for row in home_goals:
            g = min(row["goals"], 5)
            freqs[g] += 1

        # Away matches
        away_goals = db.fetchall(
            f"""SELECT {away_col} as goals FROM matches
                WHERE away_team_id = ? AND league_id = ? AND season_id = ?
                AND {away_col} IS NOT NULL""",
            (team_id, league_id, season_id),
        )
        for row in away_goals:
            g = min(row["goals"], 5)
            freqs[g] += 1

        return freqs

    def compute_standings(
        self,
        league_id: int,
        season_id: int,
        up_to_date: str | None = None,
        up_to_matchday: int | None = None,
    ) -> pd.DataFrame:
        """Calculate league table. Returns sorted DataFrame."""
        with DatabaseManager(self.db_path) as db:
            date_filter = ""
            params: tuple = (league_id, season_id)
            if up_to_matchday is not None:
                date_filter = " AND m.matchday <= ?"
                params = (league_id, season_id, up_to_matchday)
            elif up_to_date:
                date_filter = " AND m.match_date <= ?"
                params = (league_id, season_id, up_to_date)

            matches = db.to_dataframe(
                f"""SELECT m.home_team_id, m.away_team_id, m.fthg, m.ftag, m.ftr,
                           ht.name as home_team, at.name as away_team
                    FROM matches m
                    JOIN teams ht ON m.home_team_id = ht.team_id
                    JOIN teams at ON m.away_team_id = at.team_id
                    WHERE m.league_id = ? AND m.season_id = ?
                    AND m.fthg IS NOT NULL AND m.ftag IS NOT NULL
                    {date_filter}
                    ORDER BY m.match_date""",
                params,
            )

        if matches.empty:
            return pd.DataFrame(columns=["Pos", "Team", "P", "W", "D", "L", "GF", "GA", "GD", "Pts"])

        teams: dict[str, dict[str, int]] = {}
        for _, row in matches.iterrows():
            for team_name, is_home in [(row["home_team"], True), (row["away_team"], False)]:
                if team_name not in teams:
                    teams[team_name] = {"P": 0, "W": 0, "D": 0, "L": 0, "GF": 0, "GA": 0}
                t = teams[team_name]
                t["P"] += 1
                if is_home:
                    t["GF"] += row["fthg"]
                    t["GA"] += row["ftag"]
                    if row["ftr"] == "H":
                        t["W"] += 1
                    elif row["ftr"] == "D":
                        t["D"] += 1
                    else:
                        t["L"] += 1
                else:
                    t["GF"] += row["ftag"]
                    t["GA"] += row["fthg"]
                    if row["ftr"] == "A":
                        t["W"] += 1
                    elif row["ftr"] == "D":
                        t["D"] += 1
                    else:
                        t["L"] += 1

        rows = []
        for team_name, s in teams.items():
            gd = s["GF"] - s["GA"]
            pts = s["W"] * 3 + s["D"]
            rows.append({
                "Team": team_name, "P": s["P"], "W": s["W"], "D": s["D"],
                "L": s["L"], "GF": s["GF"], "GA": s["GA"], "GD": gd, "Pts": pts,
            })

        table = pd.DataFrame(rows)
        table = table.sort_values(["Pts", "GD", "GF"], ascending=[False, False, False]).reset_index(drop=True)
        table.insert(0, "Pos", range(1, len(table) + 1))
        return table

    def compute_matchdays(self, league_id: int, season_id: int) -> None:
        """Assign matchday numbers to matches in a league/season.

        Groups matches into rounds of n_teams/2 using date clustering.
        Matches within a ~4 day window are considered the same matchday.
        """
        with DatabaseManager(self.db_path) as db:
            matches = db.fetchall(
                """SELECT match_id, match_date FROM matches
                   WHERE league_id = ? AND season_id = ? AND match_date IS NOT NULL
                   ORDER BY match_date, match_id""",
                (league_id, season_id),
            )

            if not matches:
                return

            # Count distinct teams to determine matches per round
            team_count = db.fetchone(
                """SELECT COUNT(DISTINCT team_id) as n FROM (
                       SELECT home_team_id as team_id FROM matches
                       WHERE league_id = ? AND season_id = ?
                       UNION
                       SELECT away_team_id as team_id FROM matches
                       WHERE league_id = ? AND season_id = ?
                   )""",
                (league_id, season_id, league_id, season_id),
            )
            n_teams = team_count["n"] if team_count else 20
            matches_per_round = max(n_teams // 2, 1)

            # Cluster by date proximity (4-day window)
            matchday = 1
            round_count = 0
            prev_date: datetime | None = None

            for m in matches:
                curr_date = datetime.strptime(m["match_date"], "%Y-%m-%d")

                if prev_date is not None:
                    gap = (curr_date - prev_date).days
                    if gap > 4 or round_count >= matches_per_round:
                        matchday += 1
                        round_count = 0

                round_count += 1
                prev_date = curr_date

                db.execute(
                    "UPDATE matches SET matchday = ? WHERE match_id = ?",
                    (matchday, m["match_id"]),
                )

            db.commit()
            logger.info(
                "Assigned %d matchdays for league_id=%d, season_id=%d",
                matchday, league_id, season_id,
            )

    def compute_all_matchdays(self) -> None:
        """Compute matchdays for all league/season combinations."""
        with DatabaseManager(self.db_path) as db:
            combos = db.fetchall(
                "SELECT DISTINCT league_id, season_id FROM matches ORDER BY league_id, season_id"
            )
        for row in combos:
            self.compute_matchdays(row["league_id"], row["season_id"])
