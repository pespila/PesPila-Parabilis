"""Adaptive Context-Weighted Stacking (ACWS) ensemble predictor."""

from __future__ import annotations

from typing import Self

import numpy as np
from numpy.typing import NDArray
from sklearn.preprocessing import StandardScaler

from pespila.base import BaseMatchPredictor

try:
    import lightgbm as lgb

    _HAS_LIGHTGBM = True
except ImportError:
    _HAS_LIGHTGBM = False


class AdaptiveStackedPredictor(BaseMatchPredictor):
    """Adaptive Context-Weighted Stacking (ACWS) ensemble.

    Different models excel in different situations. This meta-learner dynamically
    reweights base model predictions based on match context features.

    Architecture:
    1. Base layer: Each model produces [P(H), P(D), P(A)]
    2. Context features: league tier, season phase, table position gap, form, etc.
    3. Meta-learner: LightGBM trained on [base_probs x num_models, context_features] -> [P(H), P(D), P(A)]
    4. Calibration: Platt scaling on final probabilities
    """

    name = "ACWS"

    def __init__(
        self,
        base_models: list[BaseMatchPredictor] | None = None,
        n_context_features: int = 10,
        retrain_every: int = 38,
    ) -> None:
        super().__init__()
        self.base_models = base_models or []
        self.n_context_features = n_context_features
        self.retrain_every = retrain_every
        self._meta_model: lgb.LGBMClassifier | None = None
        self._scaler = StandardScaler()

    def fit(self, X: NDArray, y: NDArray) -> Self:
        """Fit the meta-learner.

        X: array of shape (n, n_base_models * 3 + n_context_features)
            First n_base_models * 3 columns are base model probabilities [P(H), P(D), P(A)] per model.
            Remaining columns are context features.
        y: array of shape (n,) with results: 0=H, 1=D, 2=A
        """
        if not _HAS_LIGHTGBM:
            raise ImportError("LightGBM is required for AdaptiveStackedPredictor")

        X_scaled = self._scaler.fit_transform(X)

        self._meta_model = lgb.LGBMClassifier(
            n_estimators=200,
            max_depth=6,
            learning_rate=0.05,
            num_leaves=31,
            subsample=0.8,
            colsample_bytree=0.8,
            objective="multiclass",
            num_class=3,
            verbose=-1,
        )
        self._meta_model.fit(X_scaled, y)
        self.is_fitted_ = True
        return self

    def predict_proba(self, X: NDArray) -> NDArray[np.float64]:
        """Predict probabilities using the meta-learner.

        X: same format as fit().
        Returns array of shape (n, 3) with [P(H), P(D), P(A)].
        """
        if self._meta_model is None:
            raise RuntimeError("Model not fitted. Call fit() first.")

        X_scaled = self._scaler.transform(X)
        return self._meta_model.predict_proba(X_scaled)

    def build_meta_features(
        self,
        match_features: NDArray,
        context_features: NDArray,
    ) -> NDArray:
        """Combine base model predictions with context features.

        match_features: array of shape (n, feature_dim) - raw match features for base models
        context_features: array of shape (n, n_context_features)
        """
        base_preds = []
        for model in self.base_models:
            proba = model.predict_proba(match_features)
            base_preds.append(proba)

        if base_preds:
            base_matrix = np.hstack(base_preds)
            return np.hstack([base_matrix, context_features])
        return context_features
