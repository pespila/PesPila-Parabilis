"""Dixon-Coles bivariate Poisson model with low-scoring correction."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import optimize, stats

from pespila.base import BaseMatchPredictor
from pespila.types import MatchPrediction


def _tau(x: int, y: int, lam: float, mu: float, rho: float) -> float:
    """Dixon-Coles low-scoring correction factor."""
    if x == 0 and y == 0:
        return 1.0 - lam * mu * rho
    elif x == 0 and y == 1:
        return 1.0 + lam * rho
    elif x == 1 and y == 0:
        return 1.0 + mu * rho
    elif x == 1 and y == 1:
        return 1.0 - rho
    return 1.0


class DixonColesModel(BaseMatchPredictor):
    """Dixon-Coles bivariate Poisson model.

    Estimates attack/defense strength parameters per team with:
    - Home advantage factor (gamma)
    - Low-scoring correction (rho) for 0-0, 1-0, 0-1, 1-1 results
    - Optional time-decay weighting
    """

    name = "DixonColes"

    def __init__(self, xi: float = 0.005, max_goals: int = 6) -> None:
        super().__init__()
        self.xi = xi
        self.max_goals = max_goals
        self.attack_: dict[int, float] = {}
        self.defense_: dict[int, float] = {}
        self.home_adv_: float = 0.0
        self.rho_: float = 0.0
        self._teams: list[int] = []

    def fit(self, X: NDArray, y: NDArray) -> Self:
        """Fit the model.

        X: array of shape (n_matches, 3) with columns [home_team_id, away_team_id, days_ago]
        y: array of shape (n_matches, 2) with columns [home_goals, away_goals]
        """
        home_ids = X[:, 0].astype(int)
        away_ids = X[:, 1].astype(int)
        days_ago = X[:, 2].astype(float) if X.shape[1] > 2 else np.zeros(len(X))
        home_goals = y[:, 0].astype(int)
        away_goals = y[:, 1].astype(int)

        weights = np.exp(-self.xi * days_ago)

        self._teams = sorted(set(home_ids) | set(away_ids))
        team_to_idx = {t: i for i, t in enumerate(self._teams)}
        n_teams = len(self._teams)

        # Parameters: [attack_0..n-1, defense_0..n-1, home_adv, rho]
        n_params = 2 * n_teams + 2
        x0 = np.zeros(n_params)
        x0[:n_teams] = 0.0  # attack
        x0[n_teams : 2 * n_teams] = 0.0  # defense
        x0[-2] = 0.25  # home advantage (log scale)
        x0[-1] = -0.05  # rho

        def neg_log_likelihood(params: NDArray) -> float:
            attack = params[:n_teams]
            defense = params[n_teams : 2 * n_teams]
            gamma = params[-2]
            rho = params[-1]

            # Constraint: sum of attack params = n_teams (normalization)
            attack_exp = np.exp(attack)
            defense_exp = np.exp(defense)

            ll = 0.0
            for i in range(len(home_ids)):
                hi = team_to_idx[home_ids[i]]
                ai = team_to_idx[away_ids[i]]

                lam = attack_exp[hi] * defense_exp[ai] * np.exp(gamma)
                mu = attack_exp[ai] * defense_exp[hi]

                lam = max(lam, 1e-10)
                mu = max(mu, 1e-10)

                hg = int(home_goals[i])
                ag = int(away_goals[i])

                p = (
                    stats.poisson.pmf(hg, mu=lam)
                    * stats.poisson.pmf(ag, mu=mu)
                    * _tau(hg, ag, lam, mu, rho)
                )
                p = max(p, 1e-15)
                ll += weights[i] * np.log(p)

            # Regularization: sum(attack) = 0
            ll -= 10.0 * (np.sum(attack)) ** 2

            return -ll

        result = optimize.minimize(
            neg_log_likelihood,
            x0=x0,
            method="L-BFGS-B",
            options={"maxiter": 500},
        )

        params = result.x
        for i, team_id in enumerate(self._teams):
            self.attack_[team_id] = float(np.exp(params[i]))
            self.defense_[team_id] = float(np.exp(params[n_teams + i]))
        self.home_adv_ = float(np.exp(params[-2]))
        self.rho_ = float(params[-1])
        self.is_fitted_ = True
        return self

    def predict_match(self, home_team_id: int, away_team_id: int) -> MatchPrediction:
        """Predict a single match."""
        attack_h = self.attack_.get(home_team_id, 1.0)
        defense_h = self.defense_.get(home_team_id, 1.0)
        attack_a = self.attack_.get(away_team_id, 1.0)
        defense_a = self.defense_.get(away_team_id, 1.0)

        lam = attack_h * defense_a * self.home_adv_
        mu = attack_a * defense_h

        mat = np.zeros((self.max_goals, self.max_goals))
        for i in range(self.max_goals):
            for j in range(self.max_goals):
                mat[i, j] = (
                    stats.poisson.pmf(i, mu=lam)
                    * stats.poisson.pmf(j, mu=mu)
                    * _tau(i, j, lam, mu, self.rho_)
                )

        h_win = float(np.sum(np.tril(mat, -1))) * 100
        draw = float(np.sum(np.diag(mat))) * 100
        a_win = float(np.sum(np.triu(mat, 1))) * 100

        result = "H"
        if a_win > h_win and a_win > draw:
            result = "A"
        elif draw > h_win and draw > a_win:
            result = "D"

        max_idx = np.unravel_index(np.argmax(mat), mat.shape)

        return MatchPrediction(
            home_win=h_win,
            draw=draw,
            away_win=a_win,
            home_goals=int(max_idx[0]),
            away_goals=int(max_idx[1]),
            result=result,
            matrix=mat,
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
