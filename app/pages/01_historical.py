"""Historical Results page."""

from pathlib import Path

import streamlit as st
from components.league_selector import get_match_dates, league_selector
from utils.cache import get_matches
from utils.formatting import format_date

DB_PATH = Path("data/pespila.db")

st.header("Historical Results")

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="hist_")

if league_id and season_id:
    dates = get_match_dates(DB_PATH, league_id, season_id)

    if dates:
        view_all = st.sidebar.checkbox("View full season", value=False)

        if view_all:
            matches = get_matches(str(DB_PATH), league_id, season_id)
        else:
            selected_date = st.sidebar.selectbox(
                "Game Day",
                dates,
                format_func=format_date,
            )
            matches = get_matches(str(DB_PATH), league_id, season_id, selected_date)

        if not matches.empty:
            st.dataframe(
                matches.rename(columns={
                    "match_date": "Date",
                    "home_team": "Home",
                    "away_team": "Away",
                    "fthg": "HG",
                    "ftag": "AG",
                    "ftr": "Result",
                }),
                use_container_width=True,
                hide_index=True,
            )
            st.caption(f"{len(matches)} matches")
        else:
            st.info("No matches found.")
    else:
        st.info("No match dates found for this selection.")
