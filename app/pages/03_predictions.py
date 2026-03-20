"""Predictions vs Actuals page."""

from pathlib import Path

import plotly.express as px
import streamlit as st

from app.components.league_selector import get_match_dates, league_selector
from app.utils.cache import get_matches
from app.utils.formatting import format_date

DB_PATH = Path("data/pespila.db")

st.header("Predictions vs Actuals")

MODELS = ["SvS/CvC", "Dixon-Coles", "Elo", "Bradley-Terry", "Ensemble (ACWS)", "RL-DQN"]

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="pred_")

if league_id and season_id:
    model_name = st.sidebar.selectbox("Algorithm", MODELS)

    dates = get_match_dates(DB_PATH, league_id, season_id)
    if dates:
        selected_date = st.sidebar.selectbox("Game Day", dates, format_func=format_date)

        matches = get_matches(str(DB_PATH), league_id, season_id, selected_date)

        if not matches.empty:
            st.subheader(f"Results for {format_date(selected_date)}")
            st.dataframe(
                matches.rename(columns={
                    "home_team": "Home",
                    "away_team": "Away",
                    "fthg": "HG",
                    "ftag": "AG",
                    "ftr": "Result",
                })[["Home", "Away", "HG", "AG", "Result"]],
                use_container_width=True,
                hide_index=True,
            )

            st.info(f"Predictions for model '{model_name}' will be available after running the prediction pipeline.")
