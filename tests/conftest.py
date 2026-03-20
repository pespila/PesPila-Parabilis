"""Shared test fixtures."""

import numpy as np
import pytest


@pytest.fixture
def sample_frequencies():
    """Typical goal frequency vector: [f0, f1, f2, f3, f4, f5+]."""
    return np.array([5, 8, 3, 2, 1, 1], dtype=np.int64)


@pytest.fixture
def zero_heavy_frequencies():
    """Frequency vector with excess zeros (good for ZIP)."""
    return np.array([12, 5, 2, 1, 0, 0], dtype=np.int64)


@pytest.fixture
def uniform_frequencies():
    """Roughly uniform frequency distribution."""
    return np.array([4, 4, 4, 4, 3, 1], dtype=np.int64)


@pytest.fixture
def db_path(tmp_path):
    """Temporary database path."""
    return tmp_path / "test_pespila.db"
