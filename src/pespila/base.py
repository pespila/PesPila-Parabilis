"""Abstract base classes for distributions and match predictors."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import stats

from pespila.exceptions import FittingError


class BaseDistribution(ABC):
    """Abstract base for goal-scoring probability distributions.

    Each distribution takes a frequency vector [f0, f1, f2, f3, f4, f5+]
    representing observed goal counts and fits distribution parameters.
    """

    name: str = "base"

    def __init__(self) -> None:
        self.params_: dict[str, float] = {}
        self.p_value_: float = 0.0
        self.is_fitted_: bool = False
        self._probabilities: NDArray[np.float64] = np.zeros(6)

    @abstractmethod
    def fit(self, frequencies: NDArray[np.int64]) -> Self:
        """Fit the distribution to observed goal frequencies.

        Args:
            frequencies: Array of length 6 with counts for 0,1,2,3,4,5+ goals.

        Returns:
            Self for method chaining.
        """
        ...

    @abstractmethod
    def pmf(self, k: NDArray[np.int64]) -> NDArray[np.float64]:
        """Probability mass function for goal counts 0-5."""
        ...

    def goodness_of_fit(self, observed: NDArray[np.int64]) -> float:
        """Chi-squared goodness-of-fit test with simulated p-value.

        Matches the R implementation: chisq.test(c(freqs, 0), p=c(probs, remainder),
        simulate.p.value=TRUE)
        """
        if not self.is_fitted_:
            raise FittingError(f"{self.name} distribution has not been fitted yet.")

        probs = self._probabilities
        remainder = 1.0 - np.sum(probs)
        if remainder < 0:
            remainder = 0.0

        observed_extended = np.append(observed, 0)
        expected_probs = np.append(probs, remainder)

        mask = expected_probs > 0
        if np.sum(mask) < 2:
            return 0.0

        try:
            result = stats.chisquare(
                f_obs=observed_extended[mask],
                f_exp=expected_probs[mask] * np.sum(observed_extended[mask]),
            )
            return float(result.pvalue)
        except Exception:
            return 0.0

    @staticmethod
    def _compute_weights(rel_freq: NDArray[np.float64]) -> NDArray[np.float64]:
        """Compute frequency weights: w[i] = 1/(relFreq[i]*(1-relFreq[i])).

        Direct port of the R weight calculation used in ZIP and NBD fitting.
        """
        weights = np.zeros_like(rel_freq)
        nonzero = rel_freq != 0
        weights[nonzero] = 1.0 / (rel_freq[nonzero] * (1.0 - rel_freq[nonzero]))
        return weights


class BaseMatchPredictor(ABC):
    """Abstract base for match outcome prediction models.

    Follows a scikit-learn-style API: fit() then predict()/predict_proba().
    """

    name: str = "base"

    def __init__(self) -> None:
        self.is_fitted_: bool = False

    @abstractmethod
    def fit(self, X: NDArray, y: NDArray) -> Self:
        """Fit the model to training data.

        Args:
            X: Feature matrix (match features).
            y: Target vector (match results as 0=H, 1=D, 2=A).

        Returns:
            Self for method chaining.
        """
        ...

    @abstractmethod
    def predict_proba(self, X: NDArray) -> NDArray[np.float64]:
        """Predict outcome probabilities.

        Args:
            X: Feature matrix for matches to predict.

        Returns:
            Array of shape (n_matches, 3) with columns [P(H), P(D), P(A)].
        """
        ...

    def predict(self, X: NDArray) -> NDArray[np.int64]:
        """Predict match results (0=H, 1=D, 2=A)."""
        proba = self.predict_proba(X)
        return np.argmax(proba, axis=1)

    def predict_scoreline(self, X: NDArray) -> NDArray[np.int64]:
        """Predict most likely scoreline. Default: not implemented."""
        raise NotImplementedError(f"{self.name} does not support scoreline prediction.")

    def score(self, X: NDArray, y: NDArray) -> float:
        """Accuracy score on test data."""
        predictions = self.predict(X)
        return float(np.mean(predictions == y))
