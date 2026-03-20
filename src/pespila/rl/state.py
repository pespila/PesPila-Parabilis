"""State vector encoding for RL environment."""

from __future__ import annotations

from typing import Any

import numpy as np


def encode_state(
    match: dict[str, Any],
    standings: dict[str, dict[str, float]],
) -> np.ndarray:
    """Encode match context into a ~25-dimensional state vector.

    Features:
    0-1:   Home/away league position (normalized 0-1)
    2-3:   Home/away points ratio (pts / max_possible)
    4-5:   Home/away goals scored per game (season avg)
    6-7:   Home/away goals conceded per game (season avg)
    8-9:   Home/away goals scored per game (last 5)
    10-11: Home/away goals conceded per game (last 5)
    12-13: Home/away win ratio (last 5)
    14-15: Home/away draw ratio (last 5)
    16-17: Home/away loss ratio (last 5)
    18-19: H2H home wins / total, H2H away wins / total
    20:    H2H draws / total
    21:    Season progress (0-1)
    22:    League home win rate (overall)
    23:    Table position gap (normalized)
    24:    Home advantage factor
    """
    state = np.zeros(25, dtype=np.float32)

    home = match.get("home_team", "")
    away = match.get("away_team", "")
    n_teams = max(len(standings), 1)

    home_stats = standings.get(home, {})
    away_stats = standings.get(away, {})

    # Positions (normalized)
    state[0] = home_stats.get("position", n_teams / 2) / n_teams
    state[1] = away_stats.get("position", n_teams / 2) / n_teams

    # Points ratio
    max_pts = home_stats.get("played", 1) * 3
    state[2] = home_stats.get("points", 0) / max(max_pts, 1)
    max_pts = away_stats.get("played", 1) * 3
    state[3] = away_stats.get("points", 0) / max(max_pts, 1)

    # Goals per game (season)
    state[4] = home_stats.get("gf_per_game", 0.0)
    state[5] = away_stats.get("gf_per_game", 0.0)
    state[6] = home_stats.get("ga_per_game", 0.0)
    state[7] = away_stats.get("ga_per_game", 0.0)

    # Last 5 form
    state[8] = match.get("home_gf_last5", 0.0)
    state[9] = match.get("away_gf_last5", 0.0)
    state[10] = match.get("home_ga_last5", 0.0)
    state[11] = match.get("away_ga_last5", 0.0)
    state[12] = match.get("home_win_ratio_5", 0.0)
    state[13] = match.get("away_win_ratio_5", 0.0)
    state[14] = match.get("home_draw_ratio_5", 0.0)
    state[15] = match.get("away_draw_ratio_5", 0.0)
    state[16] = match.get("home_loss_ratio_5", 0.0)
    state[17] = match.get("away_loss_ratio_5", 0.0)

    # H2H
    state[18] = match.get("h2h_home_win_ratio", 0.0)
    state[19] = match.get("h2h_away_win_ratio", 0.0)
    state[20] = match.get("h2h_draw_ratio", 0.0)

    # Season progress
    state[21] = match.get("season_progress", 0.5)

    # League home win rate
    state[22] = match.get("league_home_win_rate", 0.45)

    # Position gap
    pos_gap = state[1] - state[0]  # Positive = home team higher in table
    state[23] = pos_gap

    # Home advantage factor
    state[24] = home_stats.get("home_win_rate", 0.5)

    return state
