"""PesPila-Parabilis: Soccer match prediction using statistical distribution fitting."""

from pespila._version import __version__
from pespila.base import BaseDistribution, BaseMatchPredictor
from pespila.fit_pipeline import FitPipeline
from pespila.predict import MatchPredictor
from pespila.types import MatchPrediction, TeamStrength

__all__ = [
    "__version__",
    "BaseDistribution",
    "BaseMatchPredictor",
    "FitPipeline",
    "MatchPrediction",
    "MatchPredictor",
    "TeamStrength",
]
