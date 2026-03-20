"""Predictions vs Actuals page."""

from pathlib import Path

import streamlit as st
from components.league_selector import get_matchdays, league_selector
from utils.cache import get_matches

DB_PATH = Path("data/pespila.db")

st.header("Predictions vs Actuals")

MODELS = ["SvS/CvC", "Dixon-Coles", "Elo", "Bradley-Terry", "Ensemble (ACWS)", "RL-DQN"]

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="pred_")

if league_id and season_id:
    model_name = st.sidebar.selectbox("Algorithm", MODELS)

    matchdays = get_matchdays(DB_PATH, league_id, season_id)
    if matchdays:
        selected_md = st.sidebar.selectbox(
            "Matchday",
            matchdays,
            format_func=lambda x: f"Matchday {x}",
        )

        matches = get_matches(str(DB_PATH), league_id, season_id, selected_md)

        if not matches.empty:
            st.subheader(f"Matchday {selected_md}")
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

            st.info(
                f"Predictions for model '{model_name}' will be available "
                "after running the prediction pipeline."
            )
