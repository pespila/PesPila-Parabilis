"""Styled standings table component."""

from __future__ import annotations

import pandas as pd
import streamlit as st


def render_standings(df: pd.DataFrame, n_promotion: int = 3, n_relegation: int = 3) -> None:
    """Render a styled league standings table."""
    if df.empty:
        st.info("No standings data available.")
        return

    def highlight_zones(row: pd.Series) -> list[str]:
        pos = row["Pos"]
        n_teams = len(df)
        if pos <= n_promotion:
            return ["background-color: #d4edda"] * len(row)
        elif pos > n_teams - n_relegation:
            return ["background-color: #f8d7da"] * len(row)
        return [""] * len(row)

    styled = df.style.apply(highlight_zones, axis=1).format(
        {"GD": "{:+d}", "Pts": "{:d}"},
        subset=["GD", "Pts"],
    )

    st.dataframe(styled, use_container_width=True, hide_index=True)
