"""Geometric distribution for goal frequencies."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import stats

from pespila.base import BaseDistribution


class GeometricDist(BaseDistribution):
    """Geometric distribution.

    Direct port of R Geometric() function.
    p = 1 / (lambda + 1) where lambda = mean goals.
    """

    name = "Geometric"

    def fit(self, frequencies: NDArray[np.int64]) -> Self:
        goals = np.arange(6)
        total = np.sum(frequencies)
        if total == 0:
            self.params_ = {"p": 0.0}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        lam = float(np.sum(goals * frequencies) / total)
        p = 1.0 / (lam + 1.0)
        self.params_ = {"p": p}

        probs = stats.geom.pmf(goals + 1, p=p)  # scipy geom is 1-indexed, R is 0-indexed
        # Actually R's dgeom(x, prob) gives P(X=x) = prob*(1-prob)^x for x=0,1,2,...
        # scipy.stats.geom.pmf(k, p) gives P(X=k) = p*(1-p)^(k-1) for k=1,2,...
        # So we need to use the direct formula
        probs = p * (1.0 - p) ** goals
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
        p = self.params_["p"]
        return p * (1.0 - p) ** k
