"""Streamlit caching wrappers."""

from __future__ import annotations

import pandas as pd
import streamlit as st

from pespila.data.db import DatabaseManager
from pespila.data.pipeline import DataPipeline


@st.cache_data(ttl=3600)
def get_standings(
    db_path: str, league_id: int, season_id: int, up_to_matchday: int | None = None
) -> pd.DataFrame:
    """Cached standings computation."""
    pipeline = DataPipeline(db_path=db_path)
    return pipeline.compute_standings(league_id, season_id, up_to_matchday=up_to_matchday)


@st.cache_data(ttl=3600)
def get_matches(
    db_path: str, league_id: int, season_id: int, matchday: int | None = None
) -> pd.DataFrame:
    """Cached match retrieval."""
    with DatabaseManager(db_path) as db:
        md_filter = ""
        params: tuple = (league_id, season_id)
        if matchday is not None:
            md_filter = " AND m.matchday = ?"
            params = (league_id, season_id, matchday)

        return db.to_dataframe(
            f"""SELECT m.matchday, m.match_date, ht.name as home_team, at.name as away_team,
                       m.fthg, m.ftag, m.ftr, m.b365h, m.b365d, m.b365a
                FROM matches m
                JOIN teams ht ON m.home_team_id = ht.team_id
                JOIN teams at ON m.away_team_id = at.team_id
                WHERE m.league_id = ? AND m.season_id = ?
                AND m.fthg IS NOT NULL
                {md_filter}
                ORDER BY m.matchday, m.match_date""",
            params,
        )
