"""Zero-Inflated Poisson distribution for goal frequencies."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import optimize, stats

from pespila.base import BaseDistribution


def _zip_pmf(k: NDArray, lam: float, phi: float) -> NDArray[np.float64]:
    """Zero-Inflated Poisson PMF.

    Direct port of R dzipois():
      P(0) = (1-phi) + phi*dpois(0, lambda)
      P(k) = phi*dpois(k, lambda)  for k > 0
    """
    if lam < 0 or phi < 0 or phi > 1:
        return np.full_like(k, np.nan, dtype=np.float64)

    result = np.zeros_like(k, dtype=np.float64)
    poisson_probs = stats.poisson.pmf(k, mu=lam)

    zero_mask = k == 0
    result[zero_mask] = (1.0 - phi) + phi * poisson_probs[zero_mask]
    result[~zero_mask] = phi * poisson_probs[~zero_mask]
    return result


class ZeroInflatedPoissonDist(BaseDistribution):
    """Zero-Inflated Poisson distribution.

    Direct port of R ZIP() + OptParsZIP() functions.
    """

    name = "ZIP"

    def fit(self, frequencies: NDArray[np.int64]) -> Self:
        goals = np.arange(6)
        total = np.sum(frequencies)
        if total == 0:
            self.params_ = {"lambda": 0.0, "phi": 0.0}
            self.p_value_ = 0.0
            self.is_fitted_ = True
            self._probabilities = np.zeros(6)
            return self

        rel_freq = frequencies / total
        weights = self._compute_weights(rel_freq)

        def objective(pars: NDArray) -> float:
            lam, phi = pars
            predicted = _zip_pmf(goals, lam, phi)
            if np.any(np.isnan(predicted)):
                return 1e10
            return float(np.sum(frequencies * weights * (predicted - rel_freq) ** 2))

        result = optimize.minimize(
            objective,
            x0=np.array([2.0, 0.5]),
            method="Nelder-Mead",
        )
        lam, phi = result.x
        self.params_ = {"lambda": float(lam), "phi": float(phi)}

        probs = _zip_pmf(goals, lam, phi)
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
        return _zip_pmf(k, self.params_["lambda"], self.params_["phi"])
