"""Streamlit caching wrappers."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import streamlit as st

from pespila.data.db import DatabaseManager
from pespila.data.pipeline import DataPipeline


@st.cache_data(ttl=3600)
def get_standings(db_path: str, league_id: int, season_id: int, up_to_date: str | None = None) -> pd.DataFrame:
    """Cached standings computation."""
    pipeline = DataPipeline(db_path=db_path)
    return pipeline.compute_standings(league_id, season_id, up_to_date=up_to_date)


@st.cache_data(ttl=3600)
def get_matches(db_path: str, league_id: int, season_id: int, match_date: str | None = None) -> pd.DataFrame:
    """Cached match retrieval."""
    with DatabaseManager(db_path) as db:
        date_filter = ""
        params: tuple = (league_id, season_id)
        if match_date:
            date_filter = " AND m.match_date = ?"
            params = (league_id, season_id, match_date)

        return db.to_dataframe(
            f"""SELECT m.match_date, ht.name as home_team, at.name as away_team,
                       m.fthg, m.ftag, m.ftr, m.b365h, m.b365d, m.b365a
                FROM matches m
                JOIN teams ht ON m.home_team_id = ht.team_id
                JOIN teams at ON m.away_team_id = at.team_id
                WHERE m.league_id = ? AND m.season_id = ?
                AND m.fthg IS NOT NULL
                {date_filter}
                ORDER BY m.match_date""",
            params,
        )
