"""Prediction evaluation metrics."""

from __future__ import annotations

import numpy as np
from numpy.typing import NDArray
from sklearn.metrics import log_loss


def brier_score(y_true: NDArray, y_proba: NDArray) -> float:
    """Multi-class Brier score.

    y_true: array of shape (n,) with values 0, 1, 2
    y_proba: array of shape (n, 3) with [P(H), P(D), P(A)]
    """
    y_onehot = np.zeros_like(y_proba)
    y_onehot[np.arange(len(y_true)), y_true.astype(int)] = 1.0
    return float(np.mean(np.sum((y_proba - y_onehot) ** 2, axis=1)))


def log_loss_score(y_true: NDArray, y_proba: NDArray) -> float:
    """Multi-class log loss."""
    return float(log_loss(y_true, y_proba, labels=[0, 1, 2]))


def calibration_error(
    y_true: NDArray,
    y_proba: NDArray,
    n_bins: int = 10,
) -> float:
    """Expected Calibration Error (ECE) across all classes."""
    total_ece = 0.0
    n_classes = y_proba.shape[1]

    for cls in range(n_classes):
        probs = y_proba[:, cls]
        actuals = (y_true == cls).astype(float)

        bin_edges = np.linspace(0, 1, n_bins + 1)
        for i in range(n_bins):
            mask = (probs >= bin_edges[i]) & (probs < bin_edges[i + 1])
            if np.sum(mask) == 0:
                continue
            bin_acc = np.mean(actuals[mask])
            bin_conf = np.mean(probs[mask])
            bin_size = np.sum(mask)
            total_ece += (bin_size / len(y_true)) * abs(bin_acc - bin_conf)

    return float(total_ece / n_classes)


def accuracy(y_true: NDArray, y_pred: NDArray) -> float:
    """Simple accuracy metric."""
    return float(np.mean(y_true == y_pred))


def ranked_probability_score(y_true: NDArray, y_proba: NDArray) -> float:
    """Ranked Probability Score for ordinal outcomes (H < D < A)."""
    n = len(y_true)
    rps_sum = 0.0
    for i in range(n):
        cum_pred = np.cumsum(y_proba[i])
        cum_true = np.cumsum([1.0 if y_true[i] == c else 0.0 for c in range(3)])
        rps_sum += np.sum((cum_pred - cum_true) ** 2)
    return float(rps_sum / (n * 2))
