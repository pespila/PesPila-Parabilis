# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Setup
python3 -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"          # Core + dev tools
pip install -e ".[dev,app]"      # Also install Streamlit app deps

# Tests
python -m pytest tests/ -v       # All tests
python -m pytest tests/test_distributions.py -v              # One file
python -m pytest tests/test_distributions.py::TestPoissonDist::test_fit_basic  # One test

# Lint
ruff check src/ tests/           # Check
ruff check src/ tests/ --fix     # Auto-fix

# Streamlit app
streamlit run app/app.py

# Data pipeline (populates SQLite)
python -c "from pespila.data.pipeline import DataPipeline; DataPipeline().full_refresh()"
```

## Architecture

This is a `src`-layout Python package (`src/pespila/`) migrated from a legacy R/Shiny app (`legacy/`, untouched).

### Core Prediction Flow

1. **Data in**: `data/scraper.py` async-downloads CSVs from football-data.co.uk → `data/pipeline.py` ingests into normalized SQLite via `data/db.py`
2. **Distribution fitting**: For each team/season, count goals 0-5+ → fit 5 distributions (Poisson, ZIP, NBD, Geometric, Uniform) → pick best by chi-squared p-value (`distributions/selector.py`)
3. **Prediction**: Build 6×6 probability matrix from home/away goal distributions → sum regions for P(H), P(D), P(A)
4. **Results stored** in `goal_distributions` and `predictions` tables

### Two Abstract Base Classes (`base.py`)

- **`BaseDistribution`**: `fit(frequencies) → Self`, `pmf(k)`, `goodness_of_fit()`. Frequency vector is always `[f0, f1, f2, f3, f4, f5+]` (length 6). The `_compute_weights()` static method is shared by ZIP and NBD optimizers.
- **`BaseMatchPredictor`**: scikit-learn API — `fit(X, y) → Self`, `predict_proba(X) → (n, 3)`, `predict(X)`, `score(X, y)`. Result encoding: 0=Home, 1=Draw, 2=Away.

### Models

| Model | Module | How it predicts |
|-------|--------|----------------|
| **SvSCvC** | `models/svs_cvc.py` | Legacy port. Uses DB-stored distributions, not `fit()`/`predict_proba()` — call `predict_match()` instead |
| **Dixon-Coles** | `models/dixon_coles.py` | Bivariate Poisson with τ correction. X shape: `(n, 3)` = [home_id, away_id, days_ago]. y shape: `(n, 2)` = [home_goals, away_goals] |
| **Elo** | `models/elo.py` | X: `(n, 2)` = [home_id, away_id]. y: `(n, 2)` = [home_goals, away_goals]. Builds ratings incrementally |
| **Bradley-Terry** | `models/bradley_terry.py` | X: `(n, 2)` = [home_id, away_id]. y: `(n,)` = result codes |
| **ACWS Ensemble** | `ensemble/adaptive.py` | Meta-features = `[base_probs × n_models, context_features]` → LightGBM |
| **RL-DQN** | `rl/agent.py` | Pure NumPy DQN. X: `(n, 25)` state vectors, y: `(n,)` result codes |

### Key R-to-Python Porting Details

The distribution fitting logic was ported line-by-line from `legacy/PesPila/inst/.../TestRun.R`. Critical nuances:
- R's `dnbinom(x, size=p, mu=k)` maps to `scipy.stats.nbinom.pmf(x, n=size, p=size/(size+mu))`
- R's `dgeom(x, prob)` is 0-indexed (P(X=x) = p(1-p)^x), unlike scipy's 1-indexed geom
- R's `dunif(x=1:6, ...)` in Uniform uses x=1..6, not 0..5
- Weight function: `w[i] = 1/(relFreq[i] * (1 - relFreq[i]))` for non-zero entries
- Chi-squared test appends a 7th bin for the remainder probability

### Data Layer

- **`data/registry.py`**: Static mapping of 22 leagues across 11 countries with URL patterns
- **`data/scraper.py`**: `httpx.AsyncClient` with semaphore-based rate limiting, `polars.read_csv()` for parsing
- **`data/pipeline.py`**: `full_refresh()` seeds seasons → scrapes all CSVs → inserts into `matches` table. `compute_distributions()` fits all distributions per team/season/league
- **`data/schema.py`**: 8 tables — `countries`, `leagues`, `seasons`, `teams`, `matches`, `goal_distributions`, `predictions`, `elo_ratings`, `team_strengths`
- **`data/db.py`**: `DatabaseManager` is a context manager. Uses `get_or_create_*` helpers with `INSERT OR IGNORE` for idempotency

### Streamlit App (`app/`)

Not part of the PyPI package. 4 pages share state via `app/components/league_selector.py` querying SQLite. Caching via `@st.cache_data` wrappers in `app/utils/cache.py`.

## Conventions

- Ruff enforces rules E, F, I, N, W, UP with N803/N806 ignored (allows scikit-learn-style uppercase `X`, `X_train`)
- Line length: 120 characters
- Version in `src/pespila/_version.py`, read by hatchling
