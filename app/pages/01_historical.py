"""Historical Results page."""

from pathlib import Path

import streamlit as st
from components.league_selector import get_matchdays, league_selector
from utils.cache import get_matches

DB_PATH = Path("data/pespila.db")

st.header("Historical Results")

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="hist_")

if league_id and season_id:
    matchdays = get_matchdays(DB_PATH, league_id, season_id)

    if matchdays:
        view_all = st.sidebar.checkbox("View full season", value=False)

        if view_all:
            matches = get_matches(str(DB_PATH), league_id, season_id)
        else:
            selected_md = st.sidebar.selectbox(
                "Matchday",
                matchdays,
                format_func=lambda x: f"Matchday {x}",
            )
            matches = get_matches(str(DB_PATH), league_id, season_id, selected_md)

        if not matches.empty:
            st.dataframe(
                matches.rename(columns={
                    "matchday": "MD",
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
        st.info("No matchday data found. Run compute_all_matchdays() first.")
