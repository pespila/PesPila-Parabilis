"""League Standings page with game day slider."""

from pathlib import Path

import streamlit as st
from components.league_selector import get_match_dates, league_selector
from components.standings_table import render_standings
from utils.cache import get_standings
from utils.formatting import format_date

DB_PATH = Path("data/pespila.db")

st.header("League Standings")

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="stand_")

if league_id and season_id:
    dates = get_match_dates(DB_PATH, league_id, season_id)

    if dates:
        date_idx = st.slider(
            "Game Day",
            min_value=0,
            max_value=len(dates) - 1,
            value=len(dates) - 1,
            format="Day %d",
        )
        selected_date = dates[date_idx]
        st.caption(f"Standings as of {format_date(selected_date)}")

        standings = get_standings(str(DB_PATH), league_id, season_id, up_to_date=selected_date)
        render_standings(standings)
    else:
        st.info("No match dates found.")
