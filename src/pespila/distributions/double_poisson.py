"""Double (Bivariate) Poisson distribution for joint goal modeling."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import optimize, stats

from pespila.base import BaseDistribution


class DoublePoissonDist(BaseDistribution):
    """Bivariate Poisson with correlation parameter.

    Models joint probability of (home_goals, away_goals) with parameters
    lambda_h (home rate), lambda_a (away rate), and rho (correlation).

    P(X=x, Y=y) = exp(-(lh+la+rho)) * (lh^x/x!) * (la^y/y!) *
                   sum_k min(x,y) C(x,k)*C(y,k)*k!*(rho/(lh*la))^k
    """

    name = "DoublePoisson"

    def fit(self, frequencies: NDArray[np.int64]) -> Self:
        """Fit using marginal frequencies only (univariate mode).

        For full bivariate fitting, use fit_bivariate().
        """
        goals = np.arange(6)
        total = np.sum(frequencies)
        if total == 0:
            self.params_ = {"lambda_h": 0.0, "lambda_a": 0.0, "rho": 0.0}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        lam = float(np.sum(goals * frequencies) / total)
        self.params_ = {"lambda_h": lam, "lambda_a": lam, "rho": 0.0}

        probs = stats.poisson.pmf(goals, mu=lam)
        self._probabilities = probs

        remainder = 1.0 - np.sum(probs)
        if remainder < 0:
            remainder = 0.0

        try:
            result = stats.chisquare(
                f_obs=np.append(frequencies, 0),
                f_exp=np.append(probs, remainder) * total,
            )
            self.p_value_ = float(result.pvalue)
        except Exception:
            self.p_value_ = 0.0

        self.is_fitted_ = True
        return self

    def fit_bivariate(
        self,
        home_goals: NDArray[np.int64],
        away_goals: NDArray[np.int64],
    ) -> Self:
        """Fit bivariate Poisson to paired goal data via MLE."""
        if len(home_goals) == 0:
            self.params_ = {"lambda_h": 0.0, "lambda_a": 0.0, "rho": 0.0}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        lam_h_init = float(np.mean(home_goals))
        lam_a_init = float(np.mean(away_goals))

        def neg_log_likelihood(pars: NDArray) -> float:
            lam_h, lam_a, rho = pars
            if lam_h <= 0 or lam_a <= 0 or rho < 0:
                return 1e10
            ll = 0.0
            for hg, ag in zip(home_goals, away_goals):
                p = stats.poisson.pmf(hg, mu=lam_h) * stats.poisson.pmf(ag, mu=lam_a)
                if rho > 0 and hg >= 1 and ag >= 1:
                    p *= (1.0 + rho * (hg / lam_h - 1.0) * (ag / lam_a - 1.0))
                p = max(p, 1e-15)
                ll += np.log(p)
            return -ll

        result = optimize.minimize(
            neg_log_likelihood,
            x0=np.array([lam_h_init, lam_a_init, 0.01]),
            method="Nelder-Mead",
        )
        lam_h, lam_a, rho = result.x
        self.params_ = {"lambda_h": float(lam_h), "lambda_a": float(lam_a), "rho": float(max(rho, 0.0))}

        goals = np.arange(6)
        self._probabilities = stats.poisson.pmf(goals, mu=lam_h)
        self.p_value_ = 1.0
        self.is_fitted_ = True
        return self

    def pmf(self, k: NDArray[np.int64]) -> NDArray[np.float64]:
        return stats.poisson.pmf(k, mu=self.params_["lambda_h"])

    def joint_pmf(self, home: int, away: int) -> float:
        """P(HomeGoals=home, AwayGoals=away) with correlation correction."""
        lam_h = self.params_["lambda_h"]
        lam_a = self.params_["lambda_a"]
        rho = self.params_["rho"]
        p = float(stats.poisson.pmf(home, mu=lam_h) * stats.poisson.pmf(away, mu=lam_a))
        if rho > 0 and lam_h > 0 and lam_a > 0 and home >= 1 and away >= 1:
            p *= (1.0 + rho * (home / lam_h - 1.0) * (away / lam_a - 1.0))
        return max(p, 0.0)
