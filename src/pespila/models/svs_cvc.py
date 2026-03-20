"""SvS/CvC predictor — direct port of the legacy R prediction method."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Self

import numpy as np
from numpy.typing import NDArray
from scipy import stats

from pespila.base import BaseMatchPredictor
from pespila.data.db import DatabaseManager
from pespila.types import MatchPrediction


def _zip_pmf(k: NDArray, lam: float, phi: float) -> NDArray[np.float64]:
    """Zero-Inflated Poisson PMF (matches R dzipois)."""
    result = np.zeros_like(k, dtype=np.float64)
    poisson_probs = stats.poisson.pmf(k, mu=lam)
    zero_mask = k == 0
    result[zero_mask] = (1.0 - phi) + phi * poisson_probs[zero_mask]
    result[~zero_mask] = phi * poisson_probs[~zero_mask]
    return result


def _get_probs_from_dist(dist_name: str, params: dict[str, float]) -> NDArray[np.float64]:
    """Compute P(goals=0..5) from a distribution name and its parameters.

    Direct port of the R dispatch logic in TestPredict().
    """
    goals = np.arange(6)
    probs = np.zeros(6, dtype=np.float64)

    if dist_name == "Poisson":
        probs = stats.poisson.pmf(goals, mu=params["lambda"])
    elif dist_name == "ZIP":
        probs = _zip_pmf(goals, params["lambda"], params["phi"])
    elif dist_name == "Uniform":
        a, b = params["a"], params["b"]
        if b > a:
            mask = (goals + 1).astype(float) <= b
            probs[mask] = 1.0 / (b - a)
    elif dist_name == "Geometric":
        p = params["p"]
        probs = p * (1.0 - p) ** goals
    elif dist_name == "NBD":
        k, p = params["k"], params["p"]
        if (p + k) > 0:
            prob = p / (p + k)
            probs = stats.nbinom.pmf(goals, n=p, p=prob)
    elif dist_name == "ZIWeibull":
        shape, scale, phi = params["shape"], params["scale"], params["phi"]
        for i, g in enumerate(goals):
            if g == 0:
                probs[i] = (1.0 - phi) + phi * stats.weibull_min.cdf(0.5, c=shape, scale=scale)
            else:
                upper = stats.weibull_min.cdf(g + 0.5, c=shape, scale=scale)
                lower = stats.weibull_min.cdf(g - 0.5, c=shape, scale=scale)
                probs[i] = phi * (upper - lower)

    return probs


def _build_matrix_and_predict(
    h_probs: NDArray[np.float64],
    a_probs: NDArray[np.float64],
) -> MatchPrediction:
    """Build the 6x6 probability matrix and derive H/D/A probabilities.

    Direct port of the R matrix construction and scoring logic.
    """
    mat = np.outer(h_probs, a_probs)

    h_win = 0.0
    draw = 0.0
    a_win = 0.0
    for i in range(6):
        for j in range(6):
            val = mat[i, j] * 100.0
            if i == j:
                draw += val
            elif j > i:
                a_win += val
            else:
                h_win += val

    # Determine predicted result
    result = "H"
    if a_win > h_win and a_win > draw:
        result = "A"
    if draw > a_win and draw > h_win:
        result = "D"

    # Find most likely scoreline (port of R logic)
    t_max = 0.0
    t_ind = [0, 0]
    for i in range(6):
        for j in range(6):
            if mat[i, j] >= t_max:
                t_ind = [i, j]
                if h_win > 40:
                    t_ind[0] = i + 1
                if a_win > 40:
                    t_ind[1] = j + 1
                t_max = mat[i, j]

    return MatchPrediction(
        home_win=h_win,
        draw=draw,
        away_win=a_win,
        home_goals=t_ind[0],
        away_goals=t_ind[1],
        result=result,
        matrix=mat,
    )


class SvSCvCPredictor(BaseMatchPredictor):
    """Scored-vs-Scored / Conceded-vs-Conceded predictor.

    Direct port of TestPredict() + GetLeagueTable() from the legacy R code.
    Uses pre-fitted goal distributions stored in the database.
    """

    name = "SvSCvC"

    def __init__(self, db_path: str | Path = "data/pespila.db") -> None:
        super().__init__()
        self.db_path = Path(db_path)

    def fit(self, X: NDArray, y: NDArray) -> Self:
        """No-op: this model uses pre-computed distributions from the database."""
        self.is_fitted_ = True
        return self

    def predict_match(
        self,
        home_team: str,
        away_team: str,
        season_label: str,
        league_code: str,
    ) -> dict[str, MatchPrediction]:
        """Predict a single match using SvS and CvC perspectives.

        Returns dict with keys 'svs', 'cvc', 'combined'.
        """
        with DatabaseManager(self.db_path) as db:
            home_row = db.fetchone("SELECT team_id FROM teams WHERE name = ?", (home_team,))
            away_row = db.fetchone("SELECT team_id FROM teams WHERE name = ?", (away_team,))
            season_row = db.fetchone("SELECT season_id FROM seasons WHERE label = ?", (season_label,))
            league_row = db.fetchone("SELECT league_id FROM leagues WHERE code = ?", (league_code,))

            if not all([home_row, away_row, season_row, league_row]):
                raise ValueError(
                    f"Could not find entities for {home_team} vs {away_team} ({season_label}, {league_code})"
                )

            home_id = home_row["team_id"]
            away_id = away_row["team_id"]
            season_id = season_row["season_id"]
            league_id = league_row["league_id"]

            predictions = {}

            # SvS: Home team scored distribution vs Away team scored distribution
            h_scored = self._get_dist_probs(db, home_id, season_id, league_id, "scored")
            a_scored = self._get_dist_probs(db, away_id, season_id, league_id, "scored")
            predictions["svs"] = _build_matrix_and_predict(h_scored, a_scored)

            # CvC: Home team conceded distribution vs Away team conceded distribution
            h_conceded = self._get_dist_probs(db, home_id, season_id, league_id, "conceded")
            a_conceded = self._get_dist_probs(db, away_id, season_id, league_id, "conceded")
            predictions["cvc"] = _build_matrix_and_predict(h_conceded, a_conceded)

            # Combined: average of SvS and CvC
            svs = predictions["svs"]
            cvc = predictions["cvc"]
            combined_hw = (svs.home_win + cvc.home_win) / 2.0
            combined_d = (svs.draw + cvc.draw) / 2.0
            combined_aw = (svs.away_win + cvc.away_win) / 2.0

            combined_result = "H"
            if combined_aw > combined_hw and combined_aw > combined_d:
                combined_result = "A"
            if combined_d > combined_aw and combined_d > combined_hw:
                combined_result = "D"

            combined_hg = round((svs.home_goals + cvc.home_goals) / 2)
            combined_ag = round((svs.away_goals + cvc.away_goals) / 2)

            predictions["combined"] = MatchPrediction(
                home_win=combined_hw,
                draw=combined_d,
                away_win=combined_aw,
                home_goals=combined_hg,
                away_goals=combined_ag,
                result=combined_result,
            )

        return predictions

    def _get_dist_probs(
        self,
        db: DatabaseManager,
        team_id: int,
        season_id: int,
        league_id: int,
        perspective: str,
    ) -> NDArray[np.float64]:
        """Retrieve stored distribution and compute goal probabilities."""
        row = db.fetchone(
            """SELECT best_dist, params_json FROM goal_distributions
               WHERE team_id = ? AND season_id = ? AND league_id = ? AND perspective = ?""",
            (team_id, season_id, league_id, perspective),
        )

        if not row or not row["best_dist"]:
            # Fallback: uniform distribution
            return np.full(6, 1.0 / 6.0)

        dist_name = row["best_dist"]
        params = json.loads(row["params_json"])
        return _get_probs_from_dist(dist_name, params)

    def predict_proba(self, X: NDArray) -> NDArray[np.float64]:
        """Not applicable for this model — use predict_match() instead."""
        raise NotImplementedError(
            "SvSCvCPredictor requires database access. Use predict_match() instead."
        )
