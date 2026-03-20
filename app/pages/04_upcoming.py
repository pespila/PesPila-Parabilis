"""Upcoming Matches page — placeholder until fixture data is available."""

from pathlib import Path

import streamlit as st

DB_PATH = Path("data/pespila.db")

st.header("Upcoming Matches")

st.info(
    "To predict upcoming matches, use the **Predictions** page. "
    "Select any home/away team combination and a model to get on-demand predictions."
)

st.markdown("---")
st.markdown("### How to predict")
st.markdown(
    "1. Go to the **Predictions** page\n"
    "2. Select country, league, and season\n"
    "3. Choose a prediction model\n"
    "4. Pick home and away teams\n"
    "5. Click **Predict**"
)

st.markdown("---")
st.markdown("### Available models")
st.markdown(
    "- **SvS/CvC** — Legacy distribution-based method (Poisson, ZIP, NBD, Geometric, Uniform)\n"
    "- **Dixon-Coles** — Bivariate Poisson with attack/defense strengths\n"
    "- **Elo** — Rating system with goal-difference adjustment\n"
    "- **Bradley-Terry** — Pairwise comparison model with draw extension"
)
