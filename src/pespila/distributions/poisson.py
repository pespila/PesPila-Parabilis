"""Poisson distribution for goal frequencies."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import stats

from pespila.base import BaseDistribution


class PoissonDist(BaseDistribution):
    """Poisson distribution fitted to goal frequency data.

    Direct port of R Poisson() function.
    Lambda is computed analytically: lambda = sum(goals * freqs) / sum(freqs).
    """

    name = "Poisson"

    def fit(self, frequencies: NDArray[np.int64]) -> Self:
        goals = np.arange(6)
        total = np.sum(frequencies)
        if total == 0:
            self.params_ = {"lambda": 0.0}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        lam = float(np.sum(goals * frequencies) / total)
        self.params_ = {"lambda": lam}

        probs = stats.poisson.pmf(goals, mu=lam)
        self._probabilities = probs

        remainder = 1.0 - np.sum(probs)
        if remainder < 0:
            remainder = 0.0

        try:
            result = stats.chisquare(
                f_obs=np.append(frequencies, 0),
                f_exp=np.append(probs, remainder) * (total + 0),
            )
            self.p_value_ = float(result.pvalue)
        except Exception:
            self.p_value_ = 0.0

        self.is_fitted_ = True
        return self

    def pmf(self, k: NDArray[np.int64]) -> NDArray[np.float64]:
        return stats.poisson.pmf(k, mu=self.params_["lambda"])
