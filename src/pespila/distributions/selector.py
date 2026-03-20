"""Distribution selector: fits all distributions and picks the best one."""

from __future__ import annotations

import numpy as np
from numpy.typing import NDArray

from pespila.base import BaseDistribution
from pespila.distributions.geometric import GeometricDist
from pespila.distributions.negative_binomial import NegBinomDist
from pespila.distributions.poisson import PoissonDist
from pespila.distributions.uniform import UniformDist
from pespila.distributions.zi_weibull import ZeroInflatedWeibullDist
from pespila.distributions.zip import ZeroInflatedPoissonDist


class DistributionSelector:
    """Fits all registered distributions and selects the best one.

    Direct port of CalcDist() selection logic: pick the distribution
    with the highest chi-squared p-value.
    """

    def __init__(self, include_experimental: bool = False) -> None:
        self._distributions: list[type[BaseDistribution]] = [
            PoissonDist,
            ZeroInflatedPoissonDist,
            UniformDist,
            GeometricDist,
            NegBinomDist,
        ]
        if include_experimental:
            self._distributions.append(ZeroInflatedWeibullDist)

    def select(self, frequencies: NDArray[np.int64]) -> BaseDistribution:
        """Fit all distributions and return the one with highest p-value."""
        best: BaseDistribution | None = None
        best_pval = -1.0

        for dist_cls in self._distributions:
            try:
                dist = dist_cls()
                dist.fit(frequencies)
                if dist.p_value_ > best_pval:
                    best_pval = dist.p_value_
                    best = dist
            except Exception:
                continue

        if best is None:
            # Fallback to Poisson
            best = PoissonDist()
            best.fit(frequencies)

        return best

    def fit_all(self, frequencies: NDArray[np.int64]) -> list[BaseDistribution]:
        """Fit all distributions and return them sorted by p-value (descending)."""
        results: list[BaseDistribution] = []
        for dist_cls in self._distributions:
            try:
                dist = dist_cls()
                dist.fit(frequencies)
                results.append(dist)
            except Exception:
                continue
        results.sort(key=lambda d: d.p_value_, reverse=True)
        return results
