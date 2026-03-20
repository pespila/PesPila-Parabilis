"""Tests for prediction models."""

import numpy as np

from pespila.models.bradley_terry import BradleyTerryModel
from pespila.models.dixon_coles import DixonColesModel
from pespila.models.elo import EloModel


class TestEloModel:
    def test_fit_and_predict(self):
        model = EloModel()
        X = np.array([[1, 2], [2, 3], [1, 3], [3, 1], [2, 1]], dtype=np.int64)
        y = np.array([[2, 1], [1, 1], [3, 0], [0, 2], [1, 0]], dtype=np.int64)
        model.fit(X, y)
        assert model.is_fitted_
        assert len(model.ratings_) == 3

    def test_predict_proba_shape(self):
        model = EloModel()
        X = np.array([[1, 2], [2, 3]], dtype=np.int64)
        y = np.array([[2, 1], [1, 1]], dtype=np.int64)
        model.fit(X, y)
        proba = model.predict_proba(np.array([[1, 2], [2, 1]]))
        assert proba.shape == (2, 3)
        assert np.allclose(proba.sum(axis=1), 1.0, atol=0.01)

    def test_predict_match(self):
        model = EloModel()
        X = np.array([[1, 2], [1, 2], [1, 2]], dtype=np.int64)
        y = np.array([[3, 0], [2, 1], [2, 0]], dtype=np.int64)
        model.fit(X, y)
        pred = model.predict_match(1, 2)
        assert pred.result == "H"  # Team 1 consistently wins


class TestDixonColesModel:
    def test_fit_and_predict(self):
        np.random.seed(42)
        n = 50
        teams = [1, 2, 3, 4]
        X = np.column_stack([
            np.random.choice(teams, n),
            np.random.choice(teams, n),
            np.random.randint(0, 365, n),
        ])
        # Remove self-plays
        mask = X[:, 0] != X[:, 1]
        X = X[mask]
        y = np.column_stack([
            np.random.poisson(1.5, len(X)),
            np.random.poisson(1.2, len(X)),
        ])
        model = DixonColesModel()
        model.fit(X, y)
        assert model.is_fitted_

    def test_predict_proba_sums_to_one(self):
        model = DixonColesModel()
        X = np.array([[1, 2, 0], [2, 1, 10], [1, 2, 20]], dtype=np.float64)
        y = np.array([[2, 1], [0, 1], [3, 0]], dtype=np.int64)
        model.fit(X, y)
        proba = model.predict_proba(np.array([[1, 2]]))
        assert proba.shape == (1, 3)
        assert abs(proba.sum() - 1.0) < 0.05


class TestBradleyTerryModel:
    def test_fit_and_predict(self):
        model = BradleyTerryModel()
        X = np.array([[1, 2], [2, 3], [1, 3], [3, 1], [1, 3], [1, 2]], dtype=np.int64)
        y = np.array([0, 2, 0, 0, 0, 0])  # Team 1 clearly dominates
        model.fit(X, y)
        assert model.is_fitted_
        assert len(model.strengths_) == 3

    def test_predict_proba_shape(self):
        model = BradleyTerryModel()
        X = np.array([[1, 2], [2, 3]], dtype=np.int64)
        y = np.array([0, 1])
        model.fit(X, y)
        proba = model.predict_proba(np.array([[1, 2]]))
        assert proba.shape == (1, 3)
