"""Walk-forward backtesting for match prediction models."""

from __future__ import annotations

from typing import Any

import numpy as np
import pandas as pd
from numpy.typing import NDArray

from pespila.base import BaseMatchPredictor
from pespila.evaluation.metrics import accuracy, brier_score, log_loss_score


def walk_forward_backtest(
    model: BaseMatchPredictor,
    X: NDArray,
    y: NDArray,
    initial_train_size: int = 100,
    step_size: int = 38,
    refit: bool = True,
) -> pd.DataFrame:
    """Walk-forward backtesting.

    Trains on historical data and predicts the next window of matches,
    then moves forward and repeats.

    Args:
        model: A match predictor implementing fit()/predict_proba().
        X: Feature matrix for all matches.
        y: Target array (0=H, 1=D, 2=A for predict_proba; or (n,2) goals for some models).
        initial_train_size: Number of initial training matches.
        step_size: Number of matches per prediction window (roughly 1 matchday).
        refit: Whether to refit the model at each step.

    Returns:
        DataFrame with columns: window, accuracy, brier_score, log_loss, n_matches.
    """
    n = len(X)
    results: list[dict[str, Any]] = []

    # If y is 2D (goals), create result labels
    if y.ndim == 2:
        y_labels = np.where(y[:, 0] > y[:, 1], 0, np.where(y[:, 0] == y[:, 1], 1, 2))
    else:
        y_labels = y.astype(int)

    train_end = initial_train_size

    window = 0
    while train_end < n:
        test_end = min(train_end + step_size, n)
        X_train, y_train = X[:train_end], y[:train_end]
        X_test, y_test = X[train_end:test_end], y_labels[train_end:test_end]

        if refit:
            model.fit(X_train, y_train)

        proba = model.predict_proba(X_test)
        preds = np.argmax(proba, axis=1)

        results.append({
            "window": window,
            "accuracy": accuracy(y_test, preds),
            "brier_score": brier_score(y_test, proba),
            "log_loss": log_loss_score(y_test, proba),
            "n_matches": len(y_test),
        })

        train_end = test_end
        window += 1

    return pd.DataFrame(results)
