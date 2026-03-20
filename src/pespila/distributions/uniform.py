"""Uniform distribution for goal frequencies."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import stats

from pespila.base import BaseDistribution


class UniformDist(BaseDistribution):
    """Uniform distribution.

    Direct port of R Uniform() function.
    a=0, b=2*lambda. Uses dunif(x=1:6, min=a, max=b).
    Note: R uses 1:6 (not 0:5) and continuous uniform PDF.
    """

    name = "Uniform"

    def fit(self, frequencies: NDArray[np.int64]) -> Self:
        goals = np.arange(6)
        total = np.sum(frequencies)
        if total == 0:
            self.params_ = {"a": 0.0, "b": 0.0}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        lam = float(np.sum(goals * frequencies) / total)
        a = 0.0
        b = 2.0 * lam

        # R: probs <- dunif(x = 1:6, min = a, max = b)
        # dunif gives 1/(b-a) for a <= x <= b, else 0
        # For x = 1,2,3,4,5,6 (R's 1:6)
        x_values = np.arange(1, 7, dtype=np.float64)
        if b > 0:
            probs = np.where((x_values >= a) & (x_values <= b), 1.0 / (b - a), 0.0)
        else:
            probs = np.zeros(6)

        predicted = probs * total
        index = predicted != 0

        if not np.any(index):
            self.params_ = {"a": 0.0, "b": 0.0}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        # R: chi <- sum((freqs[index]-predicted[index])^2 / predicted[index])
        # R: pval <- 1 - pchisq(chi, df = length(index) - 1)
        chi = float(np.sum((frequencies[index] - predicted[index]) ** 2 / predicted[index]))
        df = int(np.sum(index)) - 1
        if df > 0:
            p_value = 1.0 - stats.chi2.cdf(chi, df=df)
        else:
            p_value = 0.0

        self.params_ = {"a": a, "b": float(b)}
        self.p_value_ = float(p_value)
        self._probabilities = probs
        self.is_fitted_ = True
        return self

    def pmf(self, k: NDArray[np.int64]) -> NDArray[np.float64]:
        a, b = self.params_["a"], self.params_["b"]
        if b <= a:
            return np.zeros_like(k, dtype=np.float64)
        # Match R behavior: probability for goal count k
        x = k.astype(np.float64) + 1  # Shift to match R's 1:6
        return np.where((x >= a) & (x <= b), 1.0 / (b - a), 0.0)
