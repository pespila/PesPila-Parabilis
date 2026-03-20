"""Tests for ensemble and evaluation modules."""

import numpy as np

from pespila.evaluation.metrics import accuracy, brier_score, calibration_error, log_loss_score


class TestMetrics:
    def test_accuracy(self):
        y_true = np.array([0, 1, 2, 0, 1])
        y_pred = np.array([0, 1, 2, 1, 1])
        assert accuracy(y_true, y_pred) == 0.8

    def test_brier_score_perfect(self):
        y_true = np.array([0, 1, 2])
        y_proba = np.array([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]])
        assert brier_score(y_true, y_proba) == 0.0

    def test_brier_score_worst(self):
        y_true = np.array([0, 1, 2])
        y_proba = np.array([[0.0, 0.0, 1.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]])
        score = brier_score(y_true, y_proba)
        assert score > 0.0

    def test_log_loss(self):
        y_true = np.array([0, 1, 2])
        y_proba = np.array([[0.7, 0.2, 0.1], [0.1, 0.8, 0.1], [0.1, 0.1, 0.8]])
        score = log_loss_score(y_true, y_proba)
        assert score > 0.0

    def test_calibration_error(self):
        y_true = np.array([0, 0, 1, 1, 2, 2])
        y_proba = np.array([
            [0.8, 0.1, 0.1],
            [0.7, 0.2, 0.1],
            [0.1, 0.8, 0.1],
            [0.2, 0.6, 0.2],
            [0.1, 0.1, 0.8],
            [0.1, 0.2, 0.7],
        ])
        ece = calibration_error(y_true, y_proba)
        assert 0.0 <= ece <= 1.0
