"""Gymnasium environment for match prediction RL."""

from __future__ import annotations

from typing import Any

import gymnasium as gym
import numpy as np
from gymnasium import spaces

from pespila.rl.state import encode_state


class MatchPredictionEnv(gym.Env):
    """Gymnasium environment that replays seasons match-by-match.

    State: ~25-dimensional vector encoding team form, positions, etc.
    Action: Discrete(3) - predict H, D, or A
    Reward: +1 correct, -1 incorrect, +2 for exact scoreline
    """

    metadata = {"render_modes": []}

    def __init__(
        self,
        matches: list[dict[str, Any]],
        standings: dict[str, dict[str, float]] | None = None,
    ) -> None:
        super().__init__()
        self.matches = matches
        self.standings = standings or {}
        self.current_idx = 0

        self.observation_space = spaces.Box(
            low=-np.inf, high=np.inf, shape=(25,), dtype=np.float32
        )
        self.action_space = spaces.Discrete(3)  # 0=H, 1=D, 2=A

    def reset(
        self,
        *,
        seed: int | None = None,
        options: dict[str, Any] | None = None,
    ) -> tuple[np.ndarray, dict[str, Any]]:
        super().reset(seed=seed)
        self.current_idx = 0
        obs = self._get_observation()
        return obs, {}

    def step(self, action: int) -> tuple[np.ndarray, float, bool, bool, dict[str, Any]]:
        match = self.matches[self.current_idx]
        actual = match.get("result_code", 0)  # 0=H, 1=D, 2=A

        # Reward
        reward = -1.0
        if action == actual:
            reward = 1.0
            if match.get("pred_home_goals") == match.get("fthg") and match.get("pred_away_goals") == match.get("ftag"):
                reward = 2.0

        self.current_idx += 1
        terminated = self.current_idx >= len(self.matches)
        truncated = False

        obs = self._get_observation() if not terminated else np.zeros(25, dtype=np.float32)

        return obs, reward, terminated, truncated, {"match": match}

    def _get_observation(self) -> np.ndarray:
        if self.current_idx >= len(self.matches):
            return np.zeros(25, dtype=np.float32)
        return encode_state(self.matches[self.current_idx], self.standings)
