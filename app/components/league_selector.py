"""Reusable league/season selector component."""

from __future__ import annotations

from pathlib import Path

import streamlit as st

from pespila.data.db import DatabaseManager

DEFAULT_DB = Path("data/pespila.db")


def league_selector(
    db_path: Path = DEFAULT_DB,
    key_prefix: str = "",
) -> tuple[int | None, int | None, str | None]:
    """Render country/league/season selectors. Returns (league_id, season_id, season_label)."""
    with DatabaseManager(db_path) as db:
        countries = db.fetchall("SELECT DISTINCT c.name FROM countries c JOIN leagues l ON c.country_id = l.country_id ORDER BY c.name")
        country_names = [r["name"] for r in countries]

    if not country_names:
        st.warning("No data available. Run the data pipeline first.")
        return None, None, None

    country = st.sidebar.selectbox("Country", country_names, key=f"{key_prefix}country")

    with DatabaseManager(db_path) as db:
        leagues = db.fetchall(
            """SELECT l.league_id, l.name, l.code FROM leagues l
               JOIN countries c ON l.country_id = c.country_id
               WHERE c.name = ? ORDER BY l.tier""",
            (country,),
        )
        league_options = {f"{r['name']} ({r['code']})": r["league_id"] for r in leagues}

    if not league_options:
        st.warning(f"No leagues found for {country}.")
        return None, None, None

    league_label = st.sidebar.selectbox("League", list(league_options.keys()), key=f"{key_prefix}league")
    league_id = league_options[league_label]

    with DatabaseManager(db_path) as db:
        seasons = db.fetchall(
            """SELECT DISTINCT s.season_id, s.label FROM seasons s
               JOIN matches m ON s.season_id = m.season_id
               WHERE m.league_id = ?
               ORDER BY s.year_start DESC""",
            (league_id,),
        )
        season_options = {r["label"]: r["season_id"] for r in seasons}

    if not season_options:
        st.warning("No seasons found for this league.")
        return league_id, None, None

    season_label = st.sidebar.selectbox("Season", list(season_options.keys()), key=f"{key_prefix}season")
    season_id = season_options[season_label]

    return league_id, season_id, season_label


def get_match_dates(
    db_path: Path,
    league_id: int,
    season_id: int,
) -> list[str]:
    """Get distinct match dates for a league/season."""
    with DatabaseManager(db_path) as db:
        rows = db.fetchall(
            """SELECT DISTINCT match_date FROM matches
               WHERE league_id = ? AND season_id = ? AND match_date IS NOT NULL
               ORDER BY match_date""",
            (league_id, season_id),
        )
    return [r["match_date"] for r in rows]
