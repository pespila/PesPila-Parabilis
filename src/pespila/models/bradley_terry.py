"""Bradley-Terry model with Davidson extension for draws."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray

from pespila.base import BaseMatchPredictor
from pespila.types import MatchPrediction


class BradleyTerryModel(BaseMatchPredictor):
    """Bradley-Terry pairwise comparison model with draw extension.

    P(i beats j) = pi_i / (pi_i + pi_j)
    P(draw) = nu * sqrt(pi_i * pi_j) / (pi_i + pi_j + nu * sqrt(pi_i * pi_j))
    (Davidson modification)

    Fitted via MM (Minorization-Maximization) algorithm.
    """

    name = "BradleyTerry"

    def __init__(
        self,
        max_iter: int = 200,
        tol: float = 1e-6,
        home_advantage: bool = True,
    ) -> None:
        super().__init__()
        self.max_iter = max_iter
        self.tol = tol
        self.home_advantage = home_advantage
        self.strengths_: dict[int, float] = {}
        self.nu_: float = 1.0  # Draw parameter
        self.theta_: float = 1.0  # Home advantage parameter
        self._teams: list[int] = []

    def fit(self, X: NDArray, y: NDArray) -> Self:
        """Fit via iterative MM algorithm.

        X: array of shape (n, 2) with [home_team_id, away_team_id]
        y: array of shape (n,) with results: 0=home win, 1=draw, 2=away win
        """
        home_ids = X[:, 0].astype(int)
        away_ids = X[:, 1].astype(int)
        results = y.astype(int)

        self._teams = sorted(set(home_ids) | set(away_ids))
        team_to_idx = {t: i for i, t in enumerate(self._teams)}
        n_teams = len(self._teams)

        # Initialize strengths uniformly
        pi = np.ones(n_teams)
        nu = 1.0
        theta = 1.2 if self.home_advantage else 1.0

        # Count wins, draws, and total comparisons
        wins = np.zeros(n_teams)
        n_comparisons = np.zeros((n_teams, n_teams))

        for i in range(len(home_ids)):
            hi = team_to_idx[home_ids[i]]
            ai = team_to_idx[away_ids[i]]
            n_comparisons[hi, ai] += 1
            n_comparisons[ai, hi] += 1

            if results[i] == 0:  # Home win
                wins[hi] += 1
            elif results[i] == 2:  # Away win
                wins[ai] += 1
            else:  # Draw
                wins[hi] += 0.5
                wins[ai] += 0.5

        # MM iterations
        for iteration in range(self.max_iter):
            pi_old = pi.copy()

            for t in range(n_teams):
                numerator = wins[t]
                denominator = 0.0

                for s in range(n_teams):
                    if s == t or n_comparisons[t, s] == 0:
                        continue
                    denominator += n_comparisons[t, s] / (pi[t] + pi[s] + nu * np.sqrt(pi[t] * pi[s]))

                if denominator > 0:
                    pi[t] = numerator / denominator

            # Normalize
            pi /= np.mean(pi)

            # Check convergence
            if np.max(np.abs(pi - pi_old)) < self.tol:
                break

        for i, team_id in enumerate(self._teams):
            self.strengths_[team_id] = float(pi[i])
        self.nu_ = nu
        self.theta_ = theta
        self.is_fitted_ = True
        return self

    def predict_match(self, home_team_id: int, away_team_id: int) -> MatchPrediction:
        """Predict a single match."""
        pi_h = self.strengths_.get(home_team_id, 1.0) * self.theta_
        pi_a = self.strengths_.get(away_team_id, 1.0)

        denom = pi_h + pi_a + self.nu_ * np.sqrt(pi_h * pi_a)

        p_home = pi_h / denom
        p_away = pi_a / denom
        p_draw = (self.nu_ * np.sqrt(pi_h * pi_a)) / denom

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
