# pespila

Probabilistic soccer match prediction with a scikit-learn compatible API.

Four fitted models — Dixon-Coles, Bradley-Terry, Elo, and a dual-perspective distribution model — each expose `fit()`, `predict()`, and `predict_proba()` to produce calibrated Home / Draw / Away probabilities from historical match data. A library of goal-scoring distributions (Poisson, ZIP, Negative Binomial, Geometric, Zero-Inflated Weibull, Double Poisson) powers the underlying frequency analysis.

## Installation

```bash
pip install pespila
```

## Quick Start

```python
import numpy as np
from pespila.models.dixon_coles import DixonColesModel

# X: (n_matches, 3) = [home_id, away_id, days_ago]
# y: (n_matches, 2) = [home_goals, away_goals]
model = DixonColesModel(xi=0.005)
model.fit(X_train, y_train)

probs = model.predict_proba(X_test)   # → (n, 3): [P(Home), P(Draw), P(Away)]
preds = model.predict(X_test)         # → (n,):   0=Home, 1=Draw, 2=Away
accuracy = model.score(X_test, y_test)
```

## Models

| Model | Class | Input X | Input y | Method |
|-------|-------|---------|---------|--------|
| **Dixon-Coles** | `DixonColesModel` | `(n, 3)` home_id, away_id, days_ago | `(n, 2)` home_goals, away_goals | Bivariate Poisson with low-scoring correction (τ) and time-decay weighting |
| **Bradley-Terry** | `BradleyTerryModel` | `(n, 2)` home_id, away_id | `(n,)` result codes | MM algorithm with Davidson draw extension |
| **Elo** | `EloModel` | `(n, 2)` home_id, away_id | `(n, 2)` home_goals, away_goals | Incremental ratings with goal-difference scaling |
| **SvS/CvC** | `SvSCvCPredictor` | — | — | Dual-perspective 6×6 probability matrix from fitted goal distributions |

All models follow the scikit-learn estimator contract (`fit` / `predict` / `predict_proba` / `score`). Result encoding: `0 = Home win`, `1 = Draw`, `2 = Away win`.

### Dixon-Coles

```python
from pespila.models.dixon_coles import DixonColesModel

model = DixonColesModel(xi=0.005, max_goals=6)
model.fit(X, y)
model.predict_proba(X_new)             # → (n, 3)
model.predict_match(home_id, away_id)  # single prediction with full scoreline matrix
```

Estimates per-team attack/defense strengths, a home advantage factor, and a dependence parameter ρ. Recent matches are up-weighted via exponential decay controlled by `xi`.

### Bradley-Terry

```python
from pespila.models.bradley_terry import BradleyTerryModel

model = BradleyTerryModel(max_iter=200, home_advantage=True)
model.fit(X, y)
model.predict_proba(X_new)  # → (n, 3)
```

Pairwise comparison model. Draws are handled via the Davidson extension parameter ν, fitted jointly with team strengths through Minorization-Maximization.

### Elo

```python
from pespila.models.elo import EloModel

model = EloModel(k_factor=20.0, home_advantage=100.0)
model.fit(X, y)
model.predict_proba(X_new)  # → (n, 3)
```

Processes matches sequentially, updating ratings after each result. The K-factor is scaled by `log(1 + goal_difference)` to reward dominant wins.

### SvS/CvC (Scored-vs-Scored / Conceded-vs-Conceded)

```python
from pespila.models.svs_cvc import SvSCvCPredictor

predictor = SvSCvCPredictor()
result = predictor.predict_match("Arsenal", "Chelsea", "2024-25", "E0")
# → {'svs': {...}, 'cvc': {...}, 'combined': {...}}
```

A dual-perspective model ported from the original R implementation. Fits goal-scoring distributions to each team's historical frequencies, then builds a 6×6 scoreline probability matrix from two independent views (scored-vs-scored and conceded-vs-conceded).

## Goal-Scoring Distributions

Seven distributions for modelling discrete goal frequencies, all sharing a common interface:

```python
from pespila.distributions import PoissonDist

dist = PoissonDist()
dist.fit(frequencies)            # frequencies = [f0, f1, f2, f3, f4, f5+]
dist.pmf(np.arange(6))          # probability mass function
dist.goodness_of_fit(observed)   # chi-squared p-value
```

| Distribution | Class | Parameters |
|-------------|-------|------------|
| Poisson | `PoissonDist` | λ |
| Zero-Inflated Poisson | `ZeroInflatedPoissonDist` | λ, φ |
| Negative Binomial | `NegBinomDist` | k, p |
| Geometric | `GeometricDist` | p |
| Uniform | `UniformDist` | a, b |
| Zero-Inflated Weibull | `ZeroInflatedWeibullDist` | shape, scale, φ |
| Double Poisson | `DoublePoissonDist` | μ, φ |

The `DistributionSelector` fits all distributions to a frequency vector and ranks them by goodness-of-fit.

## Ensemble & Reinforcement Learning (Experimental)

- **ACWS Ensemble** (`pespila.ensemble.adaptive.AdaptiveStackedPredictor`): A LightGBM meta-learner that dynamically reweights base model predictions using match context features.
- **RL-DQN Agent** (`pespila.rl.agent`): A pure-NumPy Deep Q-Network for learning betting strategies from state vectors.

## Unified Prediction Interface

For end-to-end use with the included data pipeline:

```python
from pespila.predict import MatchPredictor

mp = MatchPredictor()
prediction = mp.predict("Dixon-Coles", "Arsenal", "Chelsea", league_id=1, season_id=32)

prediction.home_win   # 45.2 (percentage)
prediction.draw       # 27.1
prediction.away_win   # 27.7
prediction.result     # "H"
prediction.matrix     # 6×6 scoreline probability matrix
```

## Data Pipeline

An optional data pipeline downloads historical match data from football-data.co.uk into a normalized SQLite database. This is required only for the `MatchPredictor` interface and the Streamlit app — the individual model classes work with any NumPy array input.

```python
from pespila.data.pipeline import DataPipeline

pipeline = DataPipeline()
pipeline.full_refresh()          # download and ingest all leagues/seasons
pipeline.compute_all_matchdays() # assign matchday numbers
pipeline.compute_standings()     # compute league tables
```

Coverage: 22 leagues across 11 countries.

## Streamlit App

A companion dashboard (not included in the PyPI package) for interactive exploration:

```bash
pip install pespila[app]
streamlit run app/app.py
```

Features: historical match results with prediction comparison, betting P/L simulation, league tables with matchday slider, and on-demand predictions with probability heatmaps.

## License

MIT
