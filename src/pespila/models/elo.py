"""Elo rating model for match prediction."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray

from pespila.base import BaseMatchPredictor
from pespila.types import MatchPrediction


class EloModel(BaseMatchPredictor):
    """Elo rating system with goal-difference K-factor and home advantage.

    - K-factor multiplied by log(1 + goal_diff)
    - Home advantage: +100 rating points
    - Draw interval for converting win expectancy to H/D/A probabilities
    """

    name = "Elo"

    def __init__(
        self,
        k_factor: float = 20.0,
        home_advantage: float = 100.0,
        initial_rating: float = 1500.0,
        draw_interval: float = 0.1,
    ) -> None:
        super().__init__()
        self.k_factor = k_factor
        self.home_advantage = home_advantage
        self.initial_rating = initial_rating
        self.draw_interval = draw_interval
        self.ratings_: dict[int, float] = {}

    def _expected(self, rating_a: float, rating_b: float) -> float:
        """Win expectancy: E = 1 / (1 + 10^((Rb - Ra) / 400))."""
        return 1.0 / (1.0 + 10.0 ** ((rating_b - rating_a) / 400.0))

    def fit(self, X: NDArray, y: NDArray) -> Self:
        """Process historical matches to build ratings.

        X: array of shape (n, 2) with [home_team_id, away_team_id]
        y: array of shape (n, 2) with [home_goals, away_goals]
        """
        for i in range(len(X)):
            home_id, away_id = int(X[i, 0]), int(X[i, 1])
            hg, ag = int(y[i, 0]), int(y[i, 1])

            r_home = self.ratings_.get(home_id, self.initial_rating)
            r_away = self.ratings_.get(away_id, self.initial_rating)

            # Apply home advantage
            e_home = self._expected(r_home + self.home_advantage, r_away)

            # Actual result
            if hg > ag:
                s_home = 1.0
            elif hg == ag:
                s_home = 0.5
            else:
                s_home = 0.0

            # Goal-difference K-factor multiplier
            goal_diff = abs(hg - ag)
            k_mult = np.log(1.0 + goal_diff) if goal_diff > 0 else 1.0
            k = self.k_factor * k_mult

            # Update ratings
            self.ratings_[home_id] = r_home + k * (s_home - e_home)
            self.ratings_[away_id] = r_away + k * (e_home - s_home)

        self.is_fitted_ = True
        return self

    def predict_match(self, home_team_id: int, away_team_id: int) -> MatchPrediction:
        """Predict a single match using current Elo ratings."""
        r_home = self.ratings_.get(home_team_id, self.initial_rating)
        r_away = self.ratings_.get(away_team_id, self.initial_rating)

        e_home = self._expected(r_home + self.home_advantage, r_away)

        # Convert to H/D/A using draw interval
        p_draw = self.draw_interval
        p_home = max(0.0, e_home - p_draw / 2)
        p_away = max(0.0, (1.0 - e_home) - p_draw / 2)

        # Normalize
        total = p_home + p_draw + p_away
        if total > 0:
            p_home /= total
            p_draw /= total
            p_away /= total

        h_win = p_home * 100
        draw = p_draw * 100
        a_win = p_away * 100

        result = "H"
        if a_win > h_win and a_win > draw:
            result = "A"
        elif draw > h_win and draw > a_win:
            result = "D"

        return MatchPrediction(
            home_win=h_win,
            draw=draw,
            away_win=a_win,
            home_goals=1 if result == "H" else 0,
            away_goals=1 if result == "A" else 0,
            result=result,
        )

    def predict_proba(self, X: NDArray) -> NDArray[np.float64]:
        """Predict probabilities for multiple matches.

        X: array of shape (n, 2) with [home_team_id, away_team_id].
        """
        results = np.zeros((len(X), 3))
        for i in range(len(X)):
            pred = self.predict_match(int(X[i, 0]), int(X[i, 1]))
            results[i] = [pred.home_win / 100, pred.draw / 100, pred.away_win / 100]
        return results
