"""Zero-Inflated Weibull distribution for goal frequencies."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import optimize, stats

from pespila.base import BaseDistribution


def _zi_weibull_pmf(k: NDArray, shape: float, scale: float, phi: float) -> NDArray[np.float64]:
    """Zero-Inflated Weibull PMF (discretized).

    P(0) = (1-phi) + phi * F_weibull(0.5)
    P(k) = phi * [F_weibull(k+0.5) - F_weibull(k-0.5)] for k > 0
    """
    if shape <= 0 or scale <= 0 or phi < 0 or phi > 1:
        return np.full_like(k, np.nan, dtype=np.float64)

    result = np.zeros_like(k, dtype=np.float64)
    for i, ki in enumerate(k):
        if ki == 0:
            result[i] = (1.0 - phi) + phi * stats.weibull_min.cdf(0.5, c=shape, scale=scale)
        else:
            upper = stats.weibull_min.cdf(ki + 0.5, c=shape, scale=scale)
            lower = stats.weibull_min.cdf(ki - 0.5, c=shape, scale=scale)
            result[i] = phi * (upper - lower)
    return result


class ZeroInflatedWeibullDist(BaseDistribution):
    """Zero-Inflated Weibull distribution (discretized)."""

    name = "ZIWeibull"

    def fit(self, frequencies: NDArray[np.int64]) -> Self:
        goals = np.arange(6)
        total = np.sum(frequencies)
        if total == 0:
            self.params_ = {"shape": 1.0, "scale": 1.0, "phi": 0.5}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        rel_freq = frequencies / total
        weights = self._compute_weights(rel_freq)

        def objective(pars: NDArray) -> float:
            shape, scale, phi = pars
            predicted = _zi_weibull_pmf(goals, shape, scale, phi)
            if np.any(np.isnan(predicted)):
                return 1e10
            return float(np.sum(frequencies * weights * (predicted - rel_freq) ** 2))

        result = optimize.minimize(
            objective,
            x0=np.array([1.5, 1.5, 0.5]),
            method="Nelder-Mead",
        )
        shape, scale, phi = result.x
        self.params_ = {"shape": float(shape), "scale": float(scale), "phi": float(phi)}

        probs = _zi_weibull_pmf(goals, shape, scale, phi)
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
        return _zi_weibull_pmf(k, self.params_["shape"], self.params_["scale"], self.params_["phi"])
