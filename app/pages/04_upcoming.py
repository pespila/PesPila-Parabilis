"""Upcoming Matches predictions page."""

from pathlib import Path

import streamlit as st
from components.league_selector import get_matchdays, league_selector

DB_PATH = Path("data/pespila.db")

st.header("Upcoming Matches")

MODELS = ["SvS/CvC", "Dixon-Coles", "Elo", "Bradley-Terry", "Ensemble (ACWS)", "RL-DQN"]

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="up_")

if league_id and season_id:
    model_name = st.sidebar.selectbox("Algorithm", MODELS, key="up_model")

    matchdays = get_matchdays(DB_PATH, league_id, season_id)
    if matchdays:
        st.subheader(f"Latest: Matchday {matchdays[-1]}")
        st.info(
            "Upcoming match predictions will be displayed here "
            "after running the prediction pipeline with the selected model."
        )

        st.markdown("---")
        st.markdown("### Prediction Format")
        st.markdown("Each match will show:")
        st.markdown("- Horizontal stacked bar: P(H) green, P(D) gray, P(A) red")
        st.markdown("- Predicted scoreline")
        st.markdown("- Comparison with bookmaker implied probabilities (if available)")
