"""Tests for goal-scoring probability distributions."""

import numpy as np

from pespila.distributions import (
    DistributionSelector,
    GeometricDist,
    NegBinomDist,
    PoissonDist,
    UniformDist,
    ZeroInflatedPoissonDist,
)


class TestPoissonDist:
    def test_fit_basic(self, sample_frequencies):
        dist = PoissonDist()
        dist.fit(sample_frequencies)
        assert dist.is_fitted_
        assert "lambda" in dist.params_
        # Lambda = (0*5+1*8+2*3+3*2+4*1+5*1)/20 = 29/20 = 1.45
        assert abs(dist.params_["lambda"] - 1.45) < 0.01

    def test_pmf_sums_to_approximately_one(self, sample_frequencies):
        dist = PoissonDist().fit(sample_frequencies)
        goals = np.arange(6)
        probs = dist.pmf(goals)
        assert np.sum(probs) < 1.0  # Should be < 1 since we truncate at 5
        assert np.sum(probs) > 0.9  # But close to 1

    def test_pvalue_is_valid(self, sample_frequencies):
        dist = PoissonDist().fit(sample_frequencies)
        assert 0.0 <= dist.p_value_ <= 1.0

    def test_empty_frequencies(self):
        dist = PoissonDist().fit(np.zeros(6, dtype=np.int64))
        assert dist.is_fitted_
        assert dist.params_["lambda"] == 0.0


class TestZIPDist:
    def test_fit_basic(self, sample_frequencies):
        dist = ZeroInflatedPoissonDist()
        dist.fit(sample_frequencies)
        assert dist.is_fitted_
        assert "lambda" in dist.params_
        assert "phi" in dist.params_

    def test_zero_heavy_data(self, zero_heavy_frequencies):
        dist = ZeroInflatedPoissonDist().fit(zero_heavy_frequencies)
        assert dist.is_fitted_
        # With excess zeros, phi should be less than 1
        assert dist.params_["phi"] <= 1.0


class TestNegBinomDist:
    def test_fit_basic(self, sample_frequencies):
        dist = NegBinomDist()
        dist.fit(sample_frequencies)
        assert dist.is_fitted_
        assert "k" in dist.params_
        assert "p" in dist.params_

    def test_pmf_non_negative(self, sample_frequencies):
        dist = NegBinomDist().fit(sample_frequencies)
        probs = dist.pmf(np.arange(6))
        assert np.all(probs >= 0)


class TestGeometricDist:
    def test_fit_basic(self, sample_frequencies):
        dist = GeometricDist()
        dist.fit(sample_frequencies)
        assert dist.is_fitted_
        assert "p" in dist.params_
        # p = 1/(lambda+1) = 1/(1.45+1) = 1/2.45 = ~0.408
        assert abs(dist.params_["p"] - 1.0 / 2.45) < 0.01

    def test_pmf_decreasing(self, sample_frequencies):
        dist = GeometricDist().fit(sample_frequencies)
        probs = dist.pmf(np.arange(6))
        # Geometric PMF should be decreasing
        for i in range(5):
            assert probs[i] >= probs[i + 1]


class TestUniformDist:
    def test_fit_basic(self, sample_frequencies):
        dist = UniformDist()
        dist.fit(sample_frequencies)
        assert dist.is_fitted_
        assert "a" in dist.params_
        assert "b" in dist.params_
        assert dist.params_["a"] == 0.0
        # b = 2*lambda = 2*1.45 = 2.9
        assert abs(dist.params_["b"] - 2.9) < 0.01


class TestDistributionSelector:
    def test_selects_best(self, sample_frequencies):
        selector = DistributionSelector()
        best = selector.select(sample_frequencies)
        assert best.is_fitted_
        assert best.p_value_ >= 0.0
        assert best.name in {"Poisson", "ZIP", "Uniform", "Geometric", "NBD"}

    def test_fit_all_returns_sorted(self, sample_frequencies):
        selector = DistributionSelector()
        results = selector.fit_all(sample_frequencies)
        assert len(results) == 5
        # Should be sorted by p-value descending
        for i in range(len(results) - 1):
            assert results[i].p_value_ >= results[i + 1].p_value_
