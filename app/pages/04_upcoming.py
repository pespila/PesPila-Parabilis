"""Upcoming Matches predictions page."""

from pathlib import Path

import plotly.graph_objects as go
import streamlit as st

from app.components.league_selector import get_match_dates, league_selector
from app.utils.formatting import format_date

DB_PATH = Path("data/pespila.db")

st.header("Upcoming Matches")

MODELS = ["SvS/CvC", "Dixon-Coles", "Elo", "Bradley-Terry", "Ensemble (ACWS)", "RL-DQN"]

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="up_")

if league_id and season_id:
    model_name = st.sidebar.selectbox("Algorithm", MODELS, key="up_model")

    dates = get_match_dates(DB_PATH, league_id, season_id)
    if dates:
        st.subheader(f"Next game day: {format_date(dates[-1])}")
        st.info("Upcoming match predictions will be displayed here after running the prediction pipeline with the selected model.")

        # Placeholder for prediction visualization
        st.markdown("---")
        st.markdown("### Prediction Format")
        st.markdown("Each match will show:")
        st.markdown("- Horizontal stacked bar: P(H) green, P(D) gray, P(A) red")
        st.markdown("- Predicted scoreline")
        st.markdown("- Comparison with bookmaker implied probabilities (if available)")
