"""PesPila-Parabilis Streamlit application."""

import streamlit as st

st.set_page_config(
    page_title="PesPila-Parabilis",
    page_icon="⚽",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.title("PesPila-Parabilis")
st.markdown(
    "Soccer match prediction using statistical distribution fitting, "
    "ensemble methods, and reinforcement learning."
)

st.markdown("---")
st.markdown(
    """
    ### Pages
    - **Historical Results**: Browse match results by country, league, season, and game day
    - **League Standings**: Dynamic league table with game day slider
    - **Predictions vs Actuals**: Compare model predictions against actual results
    - **Upcoming Matches**: View predictions for the next unplayed game day
    """
)
