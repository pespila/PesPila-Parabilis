"""Negative Binomial distribution for goal frequencies."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import optimize, stats

from pespila.base import BaseDistribution


class NegBinomDist(BaseDistribution):
    """Negative Binomial distribution.

    Direct port of R NBD() + OptParsNBD() functions.
    Parameters: k (mu) and p (size) as per R's dnbinom(x, size=p, mu=k).
    """

    name = "NBD"

    def fit(self, frequencies: NDArray[np.int64]) -> Self:
        goals = np.arange(6)
        total = np.sum(frequencies)
        if total == 0:
            self.params_ = {"k": 0.0, "p": 0.0}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        rel_freq = frequencies / total
        weights = self._compute_weights(rel_freq)

        def objective(pars: NDArray) -> float:
            k, p = pars
            if k <= 0 or k > 5 or p <= 0 or p > 5:
                return 1e10
            try:
                # R: dnbinom(x=goals, size=pars[1], mu=pars[2])
                # In R code: Opt$par -> k=par[1], p=par[2]
                # Then: dnbinom(x=goals, mu=k, size=p)
                # scipy: nbinom.pmf(k, n, p) where n=size, p=prob
                # For mu parameterization: prob = size/(size+mu)
                prob = p / (p + k)
                predicted = stats.nbinom.pmf(goals, n=p, p=prob)
                return float(np.sum(frequencies * weights * (predicted - rel_freq) ** 2))
            except Exception:
                return 1e10

        result = optimize.minimize(
            objective,
            x0=np.array([1.0, 0.5]),
            method="Nelder-Mead",
        )
        k, p = result.x
        self.params_ = {"k": float(k), "p": float(p)}

        prob = p / (p + k) if (p + k) > 0 else 0.5
        probs = stats.nbinom.pmf(goals, n=p, p=prob)
        self._probabilities = probs

        remainder = 1.0 - np.sum(probs)
        if remainder < 0:
            remainder = 0.0

        try:
            chi_result = stats.chisquare(
                f_obs=np.append(frequencies, 0),
                f_exp=np.append(probs, remainder) * total,
            )
            self.p_value_ = float(chi_result.pvalue)
        except Exception:
            self.p_value_ = 0.0

        self.is_fitted_ = True
        return self

    def pmf(self, k: NDArray[np.int64]) -> NDArray[np.float64]:
        mu = self.params_["k"]
        size = self.params_["p"]
        prob = size / (size + mu) if (size + mu) > 0 else 0.5
        return stats.nbinom.pmf(k, n=size, p=prob)
