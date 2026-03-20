"""League Standings page with matchday slider."""

from pathlib import Path

import streamlit as st
from components.league_selector import get_matchdays, league_selector
from components.standings_table import render_standings
from utils.cache import get_standings

DB_PATH = Path("data/pespila.db")

st.header("League Standings")

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="stand_")

if league_id and season_id:
    matchdays = get_matchdays(DB_PATH, league_id, season_id)

    if matchdays:
        selected_md = st.slider(
            "Matchday",
            min_value=matchdays[0],
            max_value=matchdays[-1],
            value=matchdays[-1],
        )
        st.caption(f"Standings after Matchday {selected_md}")

        standings = get_standings(str(DB_PATH), league_id, season_id, up_to_matchday=selected_md)
        render_standings(standings)
    else:
        st.info("No matchday data found.")
