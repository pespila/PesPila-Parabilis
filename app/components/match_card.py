"""Match display component."""

from __future__ import annotations

import streamlit as st


def render_match_card(
    home_team: str,
    away_team: str,
    home_goals: int | None = None,
    away_goals: int | None = None,
    result: str | None = None,
    pred_home: float | None = None,
    pred_draw: float | None = None,
    pred_away: float | None = None,
    correct: bool | None = None,
) -> None:
    """Render a single match as a styled card."""
    score = f"{home_goals} - {away_goals}" if home_goals is not None else "vs"
    color = ""
    if correct is not None:
        color = "background-color: #1a7a3a; color: #fff;" if correct else "background-color: #a82a2a; color: #fff;"

    st.markdown(
        f"""
        <div style="padding: 10px; margin: 5px; border-radius: 8px; border: 1px solid #ddd; {color}">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <span style="font-weight: bold; width: 40%;">{home_team}</span>
                <span style="font-size: 1.2em; font-weight: bold;">{score}</span>
                <span style="font-weight: bold; width: 40%; text-align: right;">{away_team}</span>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    if pred_home is not None:
        cols = st.columns(3)
        cols[0].metric("Home", f"{pred_home:.1f}%")
        cols[1].metric("Draw", f"{pred_draw:.1f}%")
        cols[2].metric("Away", f"{pred_away:.1f}%")
