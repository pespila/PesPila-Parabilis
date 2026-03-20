"""On-demand match prediction service."""

from __future__ import annotations

import json
import logging
from pathlib import Path

import numpy as np
from numpy.typing import NDArray

from pespila.data.db import DatabaseManager
from pespila.models.bradley_terry import BradleyTerryModel
from pespila.models.dixon_coles import _tau
from pespila.models.elo import EloModel
from pespila.models.svs_cvc import _build_matrix_and_predict, _get_probs_from_dist
from pespila.types import MatchPrediction

logger = logging.getLogger(__name__)

MODELS = ["SvS/CvC", "Dixon-Coles", "Elo", "Bradley-Terry"]


class MatchPredictor:
    """Unified on-demand prediction interface.

    Loads fitted model state from the database and predicts any matchup instantly.
    Models must be fitted first via FitPipeline.
    """

    def __init__(self, db_path: str | Path = "data/pespila.db") -> None:
        self.db_path = Path(db_path)

    def predict(
        self,
        model_name: str,
        home_team: str,
        away_team: str,
        league_id: int,
        season_id: int,
    ) -> MatchPrediction:
        """Predict a single match using the specified model."""
        with DatabaseManager(self.db_path) as db:
            home_row = db.fetchone("SELECT team_id FROM teams WHERE name = ?", (home_team,))
            away_row = db.fetchone("SELECT team_id FROM teams WHERE name = ?", (away_team,))
            if not home_row or not away_row:
                raise ValueError(f"Unknown team: {home_team if not home_row else away_team}")
            home_id = home_row["team_id"]
            away_id = away_row["team_id"]

        if model_name == "SvS/CvC":
            return self._predict_svs_cvc(home_id, away_id, league_id, season_id)
        elif model_name == "Dixon-Coles":
            return self._predict_dixon_coles(home_id, away_id, league_id, season_id)
        elif model_name == "Elo":
            return self._predict_elo(home_id, away_id, league_id, season_id)
        elif model_name == "Bradley-Terry":
            return self._predict_bradley_terry(home_id, away_id, league_id, season_id)
        else:
            raise ValueError(f"Unknown model: {model_name}")

    def get_teams(self, league_id: int, season_id: int) -> list[str]:
        """Get all teams in a league/season."""
        with DatabaseManager(self.db_path) as db:
            rows = db.fetchall(
                """SELECT DISTINCT t.name FROM teams t
                   JOIN matches m ON (t.team_id = m.home_team_id OR t.team_id = m.away_team_id)
                   WHERE m.league_id = ? AND m.season_id = ?
                   ORDER BY t.name""",
                (league_id, season_id),
            )
        return [r["name"] for r in rows]

    def is_fitted(self, model_name: str, league_id: int, season_id: int) -> bool:
        """Check if a model has been fitted for this league/season."""
        with DatabaseManager(self.db_path) as db:
            if model_name == "SvS/CvC":
                row = db.fetchone(
                    "SELECT COUNT(*) as n FROM goal_distributions WHERE league_id = ? AND season_id = ?",
                    (league_id, season_id),
                )
                return row is not None and row["n"] > 0
            elif model_name in ("Dixon-Coles", "Bradley-Terry"):
                mn = "DixonColes" if model_name == "Dixon-Coles" else "BradleyTerry"
                row = db.fetchone(
                    "SELECT COUNT(*) as n FROM team_strengths WHERE league_id = ? AND season_id = ? AND model_name = ?",
                    (league_id, season_id, mn),
                )
                return row is not None and row["n"] > 0
            elif model_name == "Elo":
                row = db.fetchone(
                    """SELECT COUNT(*) as n FROM elo_ratings er
                       JOIN matches m ON er.match_id = m.match_id
                       WHERE m.league_id = ? AND m.season_id = ?""",
                    (league_id, season_id),
                )
                return row is not None and row["n"] > 0
        return False

    # --- SvS/CvC ---

    def _predict_svs_cvc(
        self, home_id: int, away_id: int, league_id: int, season_id: int
    ) -> MatchPrediction:
        with DatabaseManager(self.db_path) as db:
            h_scored = self._load_dist_probs(db, home_id, season_id, league_id, "scored")
            a_scored = self._load_dist_probs(db, away_id, season_id, league_id, "scored")
            svs = _build_matrix_and_predict(h_scored, a_scored)

            h_conceded = self._load_dist_probs(db, home_id, season_id, league_id, "conceded")
            a_conceded = self._load_dist_probs(db, away_id, season_id, league_id, "conceded")
            cvc = _build_matrix_and_predict(h_conceded, a_conceded)

        # Combined average
        hw = (svs.home_win + cvc.home_win) / 2.0
        d = (svs.draw + cvc.draw) / 2.0
        aw = (svs.away_win + cvc.away_win) / 2.0

        result = "H"
        if aw > hw and aw > d:
            result = "A"
        if d > aw and d > hw:
            result = "D"

        # Average the matrices
        mat = None
        if svs.matrix is not None and cvc.matrix is not None:
            mat = (svs.matrix + cvc.matrix) / 2.0

        hg = round((svs.home_goals + cvc.home_goals) / 2)
        ag = round((svs.away_goals + cvc.away_goals) / 2)

        return MatchPrediction(
            home_win=hw, draw=d, away_win=aw,
            home_goals=hg, away_goals=ag, result=result, matrix=mat,
        )

    def _load_dist_probs(
        self, db: DatabaseManager, team_id: int, season_id: int, league_id: int, perspective: str
    ) -> NDArray[np.float64]:
        row = db.fetchone(
            """SELECT best_dist, params_json FROM goal_distributions
               WHERE team_id = ? AND season_id = ? AND league_id = ? AND perspective = ?""",
            (team_id, season_id, league_id, perspective),
        )
        if not row or not row["best_dist"]:
            return np.full(6, 1.0 / 6.0)
        return _get_probs_from_dist(row["best_dist"], json.loads(row["params_json"]))

    # --- Dixon-Coles ---

    def _predict_dixon_coles(
        self, home_id: int, away_id: int, league_id: int, season_id: int
    ) -> MatchPrediction:
        with DatabaseManager(self.db_path) as db:
            rows = db.fetchall(
                """SELECT team_id, attack, defense, home_adv, rho FROM team_strengths
                   WHERE league_id = ? AND season_id = ? AND model_name = 'DixonColes'""",
                (league_id, season_id),
            )
        if not rows:
            raise ValueError("Dixon-Coles not fitted for this league/season. Run fit_all() first.")

        params = {r["team_id"]: r for r in rows}
        home_p = params.get(home_id)
        away_p = params.get(away_id)

        attack_h = home_p["attack"] if home_p else 1.0
        defense_h = home_p["defense"] if home_p else 1.0
        attack_a = away_p["attack"] if away_p else 1.0
        defense_a = away_p["defense"] if away_p else 1.0
        home_adv = rows[0]["home_adv"] if rows else 1.3
        rho = rows[0]["rho"] if rows else 0.0

        from scipy import stats

        lam = attack_h * defense_a * home_adv
        mu = attack_a * defense_h

        mat = np.zeros((6, 6))
        for i in range(6):
            for j in range(6):
                mat[i, j] = (
                    stats.poisson.pmf(i, mu=lam)
                    * stats.poisson.pmf(j, mu=mu)
                    * _tau(i, j, lam, mu, rho)
                )

        h_win = float(np.sum(np.tril(mat, -1))) * 100
        draw = float(np.sum(np.diag(mat))) * 100
        a_win = float(np.sum(np.triu(mat, 1))) * 100

        result = "H"
        if a_win > h_win and a_win > draw:
            result = "A"
        elif draw > h_win and draw > a_win:
            result = "D"

        max_idx = np.unravel_index(np.argmax(mat), mat.shape)

        return MatchPrediction(
            home_win=h_win, draw=draw, away_win=a_win,
            home_goals=int(max_idx[0]), away_goals=int(max_idx[1]),
            result=result, matrix=mat,
        )

    # --- Elo ---

    def _predict_elo(
        self, home_id: int, away_id: int, league_id: int, season_id: int
    ) -> MatchPrediction:
        with DatabaseManager(self.db_path) as db:
            # Get latest rating for each team in this league/season
            home_rating = db.fetchone(
                """SELECT er.rating_after FROM elo_ratings er
                   JOIN matches m ON er.match_id = m.match_id
                   WHERE er.team_id = ? AND m.league_id = ? AND m.season_id = ?
                   ORDER BY m.match_date DESC, m.match_id DESC LIMIT 1""",
                (home_id, league_id, season_id),
            )
            away_rating = db.fetchone(
                """SELECT er.rating_after FROM elo_ratings er
                   JOIN matches m ON er.match_id = m.match_id
                   WHERE er.team_id = ? AND m.league_id = ? AND m.season_id = ?
                   ORDER BY m.match_date DESC, m.match_id DESC LIMIT 1""",
                (away_id, league_id, season_id),
            )

        r_home = home_rating["rating_after"] if home_rating else 1500.0
        r_away = away_rating["rating_after"] if away_rating else 1500.0

        model = EloModel()
        model.ratings_ = {home_id: r_home, away_id: r_away}
        model.is_fitted_ = True
        return model.predict_match(home_id, away_id)

    # --- Bradley-Terry ---

    def _predict_bradley_terry(
        self, home_id: int, away_id: int, league_id: int, season_id: int
    ) -> MatchPrediction:
        with DatabaseManager(self.db_path) as db:
            rows = db.fetchall(
                """SELECT team_id, strength FROM team_strengths
                   WHERE league_id = ? AND season_id = ? AND model_name = 'BradleyTerry'""",
                (league_id, season_id),
            )
        if not rows:
            raise ValueError("Bradley-Terry not fitted. Run fit_all() first.")

        model = BradleyTerryModel()
        model.strengths_ = {r["team_id"]: r["strength"] for r in rows}
        model.is_fitted_ = True
        return model.predict_match(home_id, away_id)
