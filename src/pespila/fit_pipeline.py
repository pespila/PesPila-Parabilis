"""Model fitting pipeline — fits all models and stores parameters in the database."""

from __future__ import annotations

import logging
from datetime import datetime
from pathlib import Path

import numpy as np

from pespila.data.db import DatabaseManager
from pespila.data.pipeline import DataPipeline
from pespila.models.bradley_terry import BradleyTerryModel
from pespila.models.dixon_coles import DixonColesModel
from pespila.models.elo import EloModel

logger = logging.getLogger(__name__)


class FitPipeline:
    """Fits all prediction models for a league/season and persists results."""

    def __init__(self, db_path: str | Path = "data/pespila.db") -> None:
        self.db_path = Path(db_path)

    def fit_all(self, league_id: int, season_id: int) -> dict[str, bool]:
        """Fit all models for a league/season. Returns dict of model_name -> success."""
        results = {}
        results["SvS/CvC"] = self.fit_distributions(league_id, season_id)
        results["Dixon-Coles"] = self.fit_dixon_coles(league_id, season_id)
        results["Elo"] = self.fit_elo(league_id, season_id)
        results["Bradley-Terry"] = self.fit_bradley_terry(league_id, season_id)
        return results

    def fit_distributions(self, league_id: int, season_id: int) -> bool:
        """Fit goal distributions for SvS/CvC model."""
        try:
            pipeline = DataPipeline(db_path=self.db_path)
            pipeline.compute_distributions(league_id, season_id)
            logger.info("Fitted distributions for league=%d season=%d", league_id, season_id)
            return True
        except Exception as e:
            logger.error("Distribution fitting failed: %s", e)
            return False

    def fit_dixon_coles(self, league_id: int, season_id: int) -> bool:
        """Fit Dixon-Coles model and store attack/defense/rho in team_strengths."""
        try:
            with DatabaseManager(self.db_path) as db:
                matches = db.fetchall(
                    """SELECT m.home_team_id, m.away_team_id, m.fthg, m.ftag, m.match_date
                       FROM matches m
                       WHERE m.league_id = ? AND m.season_id = ?
                       AND m.fthg IS NOT NULL AND m.ftag IS NOT NULL
                       ORDER BY m.match_date""",
                    (league_id, season_id),
                )

            if len(matches) < 10:
                logger.warning("Too few matches (%d) for Dixon-Coles", len(matches))
                return False

            # Compute days_ago relative to most recent match
            latest = max(m["match_date"] for m in matches if m["match_date"])
            latest_dt = datetime.strptime(latest, "%Y-%m-%d")

            X = np.array([
                [
                    m["home_team_id"],
                    m["away_team_id"],
                    (latest_dt - datetime.strptime(m["match_date"], "%Y-%m-%d")).days
                    if m["match_date"] else 0,
                ]
                for m in matches
            ], dtype=np.float64)
            y = np.array([[m["fthg"], m["ftag"]] for m in matches], dtype=np.int64)

            model = DixonColesModel()
            model.fit(X, y)

            # Store in team_strengths
            with DatabaseManager(self.db_path) as db:
                for team_id in model._teams:
                    db.execute(
                        """INSERT INTO team_strengths
                           (team_id, season_id, league_id, model_name,
                            attack, defense, strength, home_adv, rho)
                           VALUES (?, ?, ?, 'DixonColes', ?, ?, 0.0, ?, ?)
                           ON CONFLICT(team_id, season_id, league_id, model_name)
                           DO UPDATE SET attack=excluded.attack, defense=excluded.defense,
                                         home_adv=excluded.home_adv, rho=excluded.rho""",
                        (
                            int(team_id), season_id, league_id,
                            model.attack_.get(team_id, 1.0),
                            model.defense_.get(team_id, 1.0),
                            model.home_adv_,
                            model.rho_,
                        ),
                    )
                db.commit()

            logger.info("Fitted Dixon-Coles for league=%d season=%d", league_id, season_id)
            return True
        except Exception as e:
            logger.error("Dixon-Coles fitting failed: %s", e)
            return False

    def fit_elo(self, league_id: int, season_id: int) -> bool:
        """Fit Elo model by processing all matches and storing ratings."""
        try:
            with DatabaseManager(self.db_path) as db:
                matches = db.fetchall(
                    """SELECT m.match_id, m.home_team_id, m.away_team_id, m.fthg, m.ftag
                       FROM matches m
                       WHERE m.league_id = ? AND m.season_id = ?
                       AND m.fthg IS NOT NULL AND m.ftag IS NOT NULL
                       ORDER BY m.match_date, m.match_id""",
                    (league_id, season_id),
                )

            if not matches:
                return False

            # Also load prior season ratings as starting points
            model = EloModel()
            with DatabaseManager(self.db_path) as db:
                prior = db.fetchall(
                    """SELECT er.team_id, er.rating_after FROM elo_ratings er
                       JOIN matches m ON er.match_id = m.match_id
                       WHERE m.league_id = ? AND m.season_id = ? - 1
                       AND er.rating_id IN (
                           SELECT MAX(er2.rating_id) FROM elo_ratings er2
                           JOIN matches m2 ON er2.match_id = m2.match_id
                           WHERE m2.league_id = ? AND m2.season_id = ? - 1
                           GROUP BY er2.team_id
                       )""",
                    (league_id, season_id, league_id, season_id),
                )
                for r in prior:
                    model.ratings_[r["team_id"]] = r["rating_after"]

            # Process each match and store ratings
            rating_rows: list[tuple] = []
            for m in matches:
                home_id, away_id = m["home_team_id"], m["away_team_id"]
                hg, ag = m["fthg"], m["ftag"]

                r_home_before = model.ratings_.get(home_id, model.initial_rating)
                r_away_before = model.ratings_.get(away_id, model.initial_rating)

                # Process single match
                X = np.array([[home_id, away_id]])
                y = np.array([[hg, ag]])
                model.fit(X, y)

                r_home_after = model.ratings_[home_id]
                r_away_after = model.ratings_[away_id]

                rating_rows.append((home_id, m["match_id"], r_home_before, r_home_after))
                rating_rows.append((away_id, m["match_id"], r_away_before, r_away_after))

            with DatabaseManager(self.db_path) as db:
                # Clear old ratings for this league/season
                db.execute(
                    """DELETE FROM elo_ratings WHERE match_id IN (
                           SELECT match_id FROM matches WHERE league_id = ? AND season_id = ?
                       )""",
                    (league_id, season_id),
                )
                db.executemany(
                    """INSERT INTO elo_ratings (team_id, match_id, rating_before, rating_after)
                       VALUES (?, ?, ?, ?)""",
                    rating_rows,
                )
                db.commit()

            logger.info("Fitted Elo for league=%d season=%d (%d matches)", league_id, season_id, len(matches))
            return True
        except Exception as e:
            logger.error("Elo fitting failed: %s", e)
            return False

    def fit_bradley_terry(self, league_id: int, season_id: int) -> bool:
        """Fit Bradley-Terry model and store strengths."""
        try:
            with DatabaseManager(self.db_path) as db:
                matches = db.fetchall(
                    """SELECT m.home_team_id, m.away_team_id, m.ftr
                       FROM matches m
                       WHERE m.league_id = ? AND m.season_id = ?
                       AND m.ftr IS NOT NULL
                       ORDER BY m.match_date""",
                    (league_id, season_id),
                )

            if len(matches) < 10:
                logger.warning("Too few matches (%d) for Bradley-Terry", len(matches))
                return False

            X = np.array([[m["home_team_id"], m["away_team_id"]] for m in matches])
            y = np.array([
                0 if m["ftr"] == "H" else (1 if m["ftr"] == "D" else 2)
                for m in matches
            ])

            model = BradleyTerryModel()
            model.fit(X, y)

            with DatabaseManager(self.db_path) as db:
                for team_id, strength in model.strengths_.items():
                    db.execute(
                        """INSERT INTO team_strengths
                           (team_id, season_id, league_id, model_name,
                            attack, defense, strength, home_adv, rho)
                           VALUES (?, ?, ?, 'BradleyTerry', 0.0, 0.0, ?, ?, ?)
                           ON CONFLICT(team_id, season_id, league_id, model_name)
                           DO UPDATE SET strength=excluded.strength,
                                         home_adv=excluded.home_adv, rho=excluded.rho""",
                        (int(team_id), season_id, league_id, strength, model.theta_, model.nu_),
                    )
                db.commit()

            logger.info("Fitted Bradley-Terry for league=%d season=%d", league_id, season_id)
            return True
        except Exception as e:
            logger.error("Bradley-Terry fitting failed: %s", e)
            return False
