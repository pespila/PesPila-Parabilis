"""Reward shaping functions for the RL agent."""

from __future__ import annotations


def standard_reward(predicted: int, actual: int) -> float:
    """Standard reward: +1 correct, -1 incorrect."""
    return 1.0 if predicted == actual else -1.0


def confidence_reward(predicted: int, actual: int, confidence: float) -> float:
    """Reward scaled by prediction confidence."""
    if predicted == actual:
        return 1.0 + confidence
    return -(1.0 + confidence)


def brier_reward(probs: list[float], actual: int) -> float:
    """Negative Brier score as reward (higher is better, range -2 to 0)."""
    target = [0.0, 0.0, 0.0]
    target[actual] = 1.0
    brier = sum((p - t) ** 2 for p, t in zip(probs, target))
    return -brier
