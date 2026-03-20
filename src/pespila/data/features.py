"""Feature engineering functions for match prediction."""

from __future__ import annotations

import numpy as np

from pespila.data.db import DatabaseManager


def compute_form(
    db: DatabaseManager,
    team_id: int,
    league_id: int,
    season_id: int,
    before_date: str,
    n_matches: int = 5,
) -> np.ndarray:
    """Compute recent form vector: [wins, draws, losses, goals_for_avg, goals_against_avg]."""
    matches = db.fetchall(
        """SELECT fthg, ftag, ftr, home_team_id
           FROM matches
           WHERE (home_team_id = ? OR away_team_id = ?)
           AND league_id = ? AND season_id = ?
           AND match_date < ? AND ftr IS NOT NULL
           ORDER BY match_date DESC LIMIT ?""",
        (team_id, team_id, league_id, season_id, before_date, n_matches),
    )

    if not matches:
        return np.array([0.0, 0.0, 0.0, 0.0, 0.0])

    wins, draws, losses = 0, 0, 0
    gf, ga = 0, 0
    for m in matches:
        is_home = m["home_team_id"] == team_id
        if is_home:
            gf += m["fthg"]
            ga += m["ftag"]
            if m["ftr"] == "H":
                wins += 1
            elif m["ftr"] == "D":
                draws += 1
            else:
                losses += 1
        else:
            gf += m["ftag"]
            ga += m["fthg"]
            if m["ftr"] == "A":
                wins += 1
            elif m["ftr"] == "D":
                draws += 1
            else:
                losses += 1

    n = len(matches)
    return np.array([wins / n, draws / n, losses / n, gf / n, ga / n])


def compute_head_to_head(
    db: DatabaseManager,
    home_team_id: int,
    away_team_id: int,
    n_matches: int = 5,
) -> np.ndarray:
    """Head-to-head record: [home_wins, draws, away_wins, avg_home_goals, avg_away_goals]."""
    matches = db.fetchall(
        """SELECT fthg, ftag, ftr FROM matches
           WHERE ((home_team_id = ? AND away_team_id = ?) OR (home_team_id = ? AND away_team_id = ?))
           AND ftr IS NOT NULL
           ORDER BY match_date DESC LIMIT ?""",
        (home_team_id, away_team_id, away_team_id, home_team_id, n_matches),
    )

    if not matches:
        return np.array([0.0, 0.0, 0.0, 0.0, 0.0])

    hw, d, aw = 0, 0, 0
    hg, ag = 0, 0
    for m in matches:
        hg += m["fthg"]
        ag += m["ftag"]
        if m["ftr"] == "H":
            hw += 1
        elif m["ftr"] == "D":
            d += 1
        else:
            aw += 1

    n = len(matches)
    return np.array([hw / n, d / n, aw / n, hg / n, ag / n])


def compute_season_progress(
    db: DatabaseManager,
    league_id: int,
    season_id: int,
    current_date: str,
) -> float:
    """Fraction of season completed (0.0 to 1.0)."""
    result = db.fetchone(
        """SELECT MIN(match_date) as first, MAX(match_date) as last
           FROM matches WHERE league_id = ? AND season_id = ? AND match_date IS NOT NULL""",
        (league_id, season_id),
    )
    if not result or not result["first"] or not result["last"]:
        return 0.5

    from datetime import datetime

    first = datetime.strptime(result["first"], "%Y-%m-%d")
    last = datetime.strptime(result["last"], "%Y-%m-%d")
    current = datetime.strptime(current_date, "%Y-%m-%d")

    total = (last - first).days
    if total <= 0:
        return 0.5
    elapsed = (current - first).days
    return max(0.0, min(1.0, elapsed / total))
