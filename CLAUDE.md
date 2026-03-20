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

# Compute matchdays (required after data ingestion)
python -c "from pespila.data.pipeline import DataPipeline; DataPipeline().compute_all_matchdays()"

# Fit all models for a league/season
python -c "from pespila.fit_pipeline import FitPipeline; FitPipeline().fit_all(league_id=1, season_id=32)"
```

## Architecture

This is a `src`-layout Python package (`src/pespila/`) migrated from a legacy R/Shiny app (`legacy/`, untouched).

### Core Prediction Flow

1. **Data in**: `data/scraper.py` async-downloads CSVs from football-data.co.uk → `data/pipeline.py` ingests into normalized SQLite via `data/db.py`
2. **Matchday assignment**: `pipeline.compute_all_matchdays()` clusters matches into rounds (n_teams/2 per matchday, 4-day date window)
3. **Model fitting**: `fit_pipeline.FitPipeline.fit_all()` fits all 4 models and stores params in DB (goal_distributions, team_strengths, elo_ratings tables)
4. **On-demand prediction**: `predict.MatchPredictor.predict()` loads fitted params from DB → computes H/D/A probabilities instantly

### Two Abstract Base Classes (`base.py`)

- **`BaseDistribution`**: `fit(frequencies) → Self`, `pmf(k)`, `goodness_of_fit()`. Frequency vector is always `[f0, f1, f2, f3, f4, f5+]` (length 6). The `_compute_weights()` static method is shared by ZIP and NBD optimizers.
- **`BaseMatchPredictor`**: scikit-learn API — `fit(X, y) → Self`, `predict_proba(X) → (n, 3)`, `predict(X)`, `score(X, y)`. Result encoding: 0=Home, 1=Draw, 2=Away.

### Fit → Predict Architecture

Two key orchestrators connect models to the database:

- **`fit_pipeline.FitPipeline`**: Fits models and persists state. `fit_distributions()` stores in `goal_distributions`, `fit_dixon_coles()`/`fit_bradley_terry()` store in `team_strengths` (using `INSERT ... ON CONFLICT DO UPDATE` to avoid FK cascade issues), `fit_elo()` stores in `elo_ratings`.
- **`predict.MatchPredictor`**: Unified prediction interface. `predict(model_name, home, away, league_id, season_id) → MatchPrediction`. Loads fitted params from DB, instantiates a lightweight model object, and computes probabilities. `is_fitted()` checks if a model has been trained for a league/season. `get_teams()` returns available teams.

### Models

| Model | Module | How it predicts |
|-------|--------|----------------|
| **SvSCvC** | `models/svs_cvc.py` | Legacy port. Uses DB-stored distributions, builds 6×6 probability matrix from home/away goal PMFs |
| **Dixon-Coles** | `models/dixon_coles.py` | Bivariate Poisson with τ correction. X shape: `(n, 3)` = [home_id, away_id, days_ago]. y shape: `(n, 2)` = [home_goals, away_goals] |
| **Elo** | `models/elo.py` | X: `(n, 2)` = [home_id, away_id]. y: `(n, 2)` = [home_goals, away_goals]. Builds ratings incrementally. Loads prior season ratings as starting points |
| **Bradley-Terry** | `models/bradley_terry.py` | X: `(n, 2)` = [home_id, away_id]. y: `(n,)` = result codes. MM algorithm with Davidson draw extension |
| **ACWS Ensemble** | `ensemble/adaptive.py` | Meta-features = `[base_probs × n_models, context_features]` → LightGBM (not yet integrated into MatchPredictor) |
| **RL-DQN** | `rl/agent.py` | Pure NumPy DQN. X: `(n, 25)` state vectors, y: `(n,)` result codes (not yet integrated into MatchPredictor) |

### Key R-to-Python Porting Details

The distribution fitting logic was ported line-by-line from `legacy/PesPila/inst/.../TestRun.R`. Critical nuances:
- R's `dnbinom(x, size=p, mu=k)` maps to `scipy.stats.nbinom.pmf(x, n=size, p=size/(size+mu))`
- R's `dgeom(x, prob)` is 0-indexed (P(X=x) = p(1-p)^x), unlike scipy's 1-indexed geom
- R's `dunif(x=1:6, ...)` in Uniform uses x=1..6, not 0..5
- Weight function: `w[i] = 1/(relFreq[i] * (1 - relFreq[i]))` for non-zero entries
- Chi-squared test appends a 7th bin for the remainder probability

### Data Layer

- **`data/registry.py`**: Static mapping of 22 leagues across 11 countries with URL patterns
- **`data/scraper.py`**: `httpx.AsyncClient` with semaphore-based rate limiting, `polars.read_csv()` for parsing. Note: football-data.co.uk has Cloudflare protection — scraping may require downloading CSVs externally (e.g., via Colab) and ingesting from a local zip
- **`data/pipeline.py`**: `full_refresh()` seeds seasons → scrapes all CSVs → inserts into `matches` table (INSERT OR IGNORE for idempotent re-ingestion). `compute_distributions()` fits all distributions per team/season/league. `compute_matchdays()` assigns matchday numbers via date clustering. `compute_standings()` calculates league table up to any matchday
- **`data/schema.py`**: 8 tables — `countries`, `leagues`, `seasons`, `teams`, `matches` (includes `matchday INTEGER`), `goal_distributions`, `predictions`, `elo_ratings`, `team_strengths`
- **`data/db.py`**: `DatabaseManager` is a context manager with WAL mode and FK enforcement. Uses `get_or_create_*` helpers with `INSERT OR IGNORE` for idempotency

### Streamlit App (`app/`)

Not part of the PyPI package. Streamlit adds `app/` to `sys.path`, so imports are `from components.X` not `from app.components.X`.

- **01_historical.py**: Match results + prediction comparison + betting P/L simulation. Shows per-matchday accuracy, and a full-season simulation with cumulative P/L chart and per-matchday accuracy bar chart using b365 odds
- **02_standings.py**: League table with matchday slider, promotion/relegation zone coloring
- **03_predictions.py**: On-demand predictions with team dropdowns and model selector. Includes "Fit now" button, 6×6 probability heatmap, and odds comparison
- **04_upcoming.py**: Placeholder (no fixture data source yet)
- **Shared**: `components/league_selector.py` (country→league→season→matchday), `utils/cache.py` (`@st.cache_data` wrappers)

## Conventions

- Ruff enforces rules E, F, I, N, W, UP with N803/N806 ignored (allows scikit-learn-style uppercase `X`, `X_train`)
- N999 per-file-ignored for `app/pages/*.py` (Streamlit requires numeric-prefixed page names)
- Line length: 120 characters
- Version in `src/pespila/_version.py`, read by hatchling
- Use `INSERT ... ON CONFLICT DO UPDATE` instead of `INSERT OR REPLACE` for tables with foreign key references (avoids cascading deletes)
