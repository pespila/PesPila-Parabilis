"""Core data types used across the package."""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np
from numpy.typing import NDArray


@dataclass(frozen=True)
class MatchPrediction:
    """Result of a match prediction."""

    home_win: float
    draw: float
    away_win: float
    home_goals: int
    away_goals: int
    result: str  # "H", "D", or "A"
    matrix: NDArray[np.float64] | None = field(default=None, repr=False)

    @property
    def home_odd(self) -> float:
        return max((100.0 / self.home_win) - 1.0, 1.0) if self.home_win > 0 else float("inf")

    @property
    def draw_odd(self) -> float:
        return max((100.0 / self.draw) - 1.0, 1.0) if self.draw > 0 else float("inf")

    @property
    def away_odd(self) -> float:
        return max((100.0 / self.away_win) - 1.0, 1.0) if self.away_win > 0 else float("inf")

    def probabilities(self) -> NDArray[np.float64]:
        return np.array([self.home_win, self.draw, self.away_win]) / 100.0


@dataclass
class TeamStrength:
    """Fitted strength parameters for a team."""

    team_id: int
    season_id: int
    league_id: int
    model_name: str
    attack: float = 0.0
    defense: float = 0.0
    strength: float = 0.0
    home_advantage: float = 0.0
    rho: float = 0.0


@dataclass(frozen=True)
class DistributionFit:
    """Result of fitting a distribution to goal frequencies."""

    name: str
    params: dict[str, float]
    p_value: float
    probabilities: NDArray[np.float64]
