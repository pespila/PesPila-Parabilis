"""Database schema definitions (DDL)."""

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS countries (
    country_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS leagues (
    league_id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER NOT NULL REFERENCES countries(country_id),
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    tier INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS seasons (
    season_id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT NOT NULL UNIQUE,
    year_start INTEGER NOT NULL,
    year_end INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS teams (
    team_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS matches (
    match_id INTEGER PRIMARY KEY AUTOINCREMENT,
    league_id INTEGER NOT NULL REFERENCES leagues(league_id),
    season_id INTEGER NOT NULL REFERENCES seasons(season_id),
    match_date TEXT,
    home_team_id INTEGER NOT NULL REFERENCES teams(team_id),
    away_team_id INTEGER NOT NULL REFERENCES teams(team_id),
    fthg INTEGER,
    ftag INTEGER,
    ftr TEXT,
    hthg INTEGER,
    htag INTEGER,
    htr TEXT,
    b365h REAL,
    b365d REAL,
    b365a REAL,
    matchday INTEGER,
    UNIQUE(league_id, season_id, home_team_id, away_team_id, match_date)
);

CREATE TABLE IF NOT EXISTS goal_distributions (
    dist_id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_id INTEGER NOT NULL REFERENCES teams(team_id),
    season_id INTEGER NOT NULL REFERENCES seasons(season_id),
    league_id INTEGER NOT NULL REFERENCES leagues(league_id),
    perspective TEXT NOT NULL CHECK(perspective IN ('scored', 'conceded')),
    freq_0 INTEGER NOT NULL DEFAULT 0,
    freq_1 INTEGER NOT NULL DEFAULT 0,
    freq_2 INTEGER NOT NULL DEFAULT 0,
    freq_3 INTEGER NOT NULL DEFAULT 0,
    freq_4 INTEGER NOT NULL DEFAULT 0,
    freq_5plus INTEGER NOT NULL DEFAULT 0,
    best_dist TEXT,
    best_pvalue REAL,
    params_json TEXT,
    UNIQUE(team_id, season_id, league_id, perspective)
);

CREATE TABLE IF NOT EXISTS predictions (
    prediction_id INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id INTEGER NOT NULL REFERENCES matches(match_id),
    model_name TEXT NOT NULL,
    prob_home REAL,
    prob_draw REAL,
    prob_away REAL,
    pred_home_goals INTEGER,
    pred_away_goals INTEGER,
    pred_result TEXT,
    UNIQUE(match_id, model_name)
);

CREATE TABLE IF NOT EXISTS elo_ratings (
    rating_id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_id INTEGER NOT NULL REFERENCES teams(team_id),
    match_id INTEGER NOT NULL REFERENCES matches(match_id),
    rating_before REAL NOT NULL,
    rating_after REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS team_strengths (
    strength_id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_id INTEGER NOT NULL REFERENCES teams(team_id),
    season_id INTEGER NOT NULL REFERENCES seasons(season_id),
    league_id INTEGER NOT NULL REFERENCES leagues(league_id),
    model_name TEXT NOT NULL,
    attack REAL NOT NULL DEFAULT 0.0,
    defense REAL NOT NULL DEFAULT 0.0,
    strength REAL NOT NULL DEFAULT 0.0,
    home_adv REAL NOT NULL DEFAULT 0.0,
    rho REAL NOT NULL DEFAULT 0.0,
    UNIQUE(team_id, season_id, league_id, model_name)
);

CREATE INDEX IF NOT EXISTS idx_matches_league_season ON matches(league_id, season_id);
CREATE INDEX IF NOT EXISTS idx_matches_teams ON matches(home_team_id, away_team_id);
CREATE INDEX IF NOT EXISTS idx_matches_date ON matches(match_date);
CREATE INDEX IF NOT EXISTS idx_goal_dist_team ON goal_distributions(team_id, season_id, league_id);
CREATE INDEX IF NOT EXISTS idx_predictions_match ON predictions(match_id);
CREATE INDEX IF NOT EXISTS idx_elo_team ON elo_ratings(team_id);
CREATE INDEX IF NOT EXISTS idx_strengths_team ON team_strengths(team_id, season_id, league_id);
"""
