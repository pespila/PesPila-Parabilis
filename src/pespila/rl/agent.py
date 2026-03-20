"""Lightweight DQN agent implemented in pure NumPy."""

from __future__ import annotations

import random
from collections import deque
from typing import Self

import numpy as np
from numpy.typing import NDArray

from pespila.base import BaseMatchPredictor


class _NumpyNetwork:
    """Simple feedforward network: Linear(25,128)->ReLU->Linear(128,64)->ReLU->Linear(64,3)->Softmax."""

    def __init__(self, input_dim: int = 25, hidden1: int = 128, hidden2: int = 64, output_dim: int = 3) -> None:
        scale1 = np.sqrt(2.0 / input_dim)
        scale2 = np.sqrt(2.0 / hidden1)
        scale3 = np.sqrt(2.0 / hidden2)
        self.w1 = np.random.randn(input_dim, hidden1).astype(np.float32) * scale1
        self.b1 = np.zeros(hidden1, dtype=np.float32)
        self.w2 = np.random.randn(hidden1, hidden2).astype(np.float32) * scale2
        self.b2 = np.zeros(hidden2, dtype=np.float32)
        self.w3 = np.random.randn(hidden2, output_dim).astype(np.float32) * scale3
        self.b3 = np.zeros(output_dim, dtype=np.float32)

    def forward(self, x: NDArray) -> NDArray:
        h1 = np.maximum(0, x @ self.w1 + self.b1)  # ReLU
        h2 = np.maximum(0, h1 @ self.w2 + self.b2)  # ReLU
        logits = h2 @ self.w3 + self.b3
        # Softmax
        exp_logits = np.exp(logits - np.max(logits, axis=-1, keepdims=True))
        return exp_logits / np.sum(exp_logits, axis=-1, keepdims=True)

    def copy_from(self, other: _NumpyNetwork) -> None:
        self.w1 = other.w1.copy()
        self.b1 = other.b1.copy()
        self.w2 = other.w2.copy()
        self.b2 = other.b2.copy()
        self.w3 = other.w3.copy()
        self.b3 = other.b3.copy()

    def parameters(self) -> list[NDArray]:
        return [self.w1, self.b1, self.w2, self.b2, self.w3, self.b3]


class PredictionAgent(BaseMatchPredictor):
    """DQN-based match prediction agent implemented in pure NumPy.

    Uses experience replay, epsilon-greedy exploration with decay,
    and a target network for stability.
    """

    name = "RL-DQN"

    def __init__(
        self,
        learning_rate: float = 0.001,
        gamma: float = 0.95,
        epsilon_start: float = 1.0,
        epsilon_end: float = 0.05,
        epsilon_decay: float = 0.995,
        buffer_size: int = 10000,
        batch_size: int = 64,
        target_update_freq: int = 100,
    ) -> None:
        super().__init__()
        self.lr = learning_rate
        self.gamma = gamma
        self.epsilon = epsilon_start
        self.epsilon_end = epsilon_end
        self.epsilon_decay = epsilon_decay
        self.batch_size = batch_size
        self.target_update_freq = target_update_freq

        self.policy_net = _NumpyNetwork()
        self.target_net = _NumpyNetwork()
        self.target_net.copy_from(self.policy_net)
        self.replay_buffer: deque[tuple] = deque(maxlen=buffer_size)
        self._step_count = 0

    def select_action(self, state: NDArray) -> int:
        """Epsilon-greedy action selection."""
        if random.random() < self.epsilon:
            return random.randint(0, 2)
        probs = self.policy_net.forward(state.reshape(1, -1))[0]
        return int(np.argmax(probs))

    def store_transition(
        self,
        state: NDArray,
        action: int,
        reward: float,
        next_state: NDArray,
        done: bool,
    ) -> None:
        self.replay_buffer.append((state, action, reward, next_state, done))

    def train_step(self) -> float:
        """Perform one training step using experience replay."""
        if len(self.replay_buffer) < self.batch_size:
            return 0.0

        batch = random.sample(list(self.replay_buffer), self.batch_size)
        states = np.array([t[0] for t in batch])
        actions = np.array([t[1] for t in batch])
        rewards = np.array([t[2] for t in batch])
        next_states = np.array([t[3] for t in batch])
        dones = np.array([t[4] for t in batch], dtype=np.float32)

        # Current Q-values (using policy as probs * 100 as proxy)
        current_probs = self.policy_net.forward(states)
        next_probs = self.target_net.forward(next_states)

        # Target: reward + gamma * max(next_Q) * (1 - done)
        max_next = np.max(next_probs, axis=1)
        targets = rewards + self.gamma * max_next * (1.0 - dones)

        # Compute gradient and update (simplified SGD on cross-entropy-like loss)
        for i in range(self.batch_size):
            a = actions[i]
            error = targets[i] - current_probs[i, a]

            # Backprop through softmax output layer
            h1 = np.maximum(0, states[i] @ self.policy_net.w1 + self.policy_net.b1)
            h2 = np.maximum(0, h1 @ self.policy_net.w2 + self.policy_net.b2)
            grad_w3 = np.outer(h2, np.zeros(3))
            grad_w3[:, a] = h2 * error * self.lr / self.batch_size
            self.policy_net.w3 += grad_w3
            self.policy_net.b3[a] += error * self.lr / self.batch_size

        self._step_count += 1
        if self._step_count % self.target_update_freq == 0:
            self.target_net.copy_from(self.policy_net)

        # Decay epsilon
        self.epsilon = max(self.epsilon_end, self.epsilon * self.epsilon_decay)

        return float(np.mean(np.abs(targets - current_probs[np.arange(self.batch_size), actions])))

    def fit(self, X: NDArray, y: NDArray) -> Self:
        """Train on state vectors and results.

        X: array of shape (n, 25) - state vectors
        y: array of shape (n,) - results (0=H, 1=D, 2=A)
        """
        for i in range(len(X)):
            state = X[i]
            action = self.select_action(state)
            actual = int(y[i])
            reward = 1.0 if action == actual else -1.0
            next_state = X[i + 1] if i + 1 < len(X) else np.zeros(25)
            done = i + 1 >= len(X)

            self.store_transition(state, action, reward, next_state, done)
            self.train_step()

        self.is_fitted_ = True
        return self

    def predict_proba(self, X: NDArray) -> NDArray[np.float64]:
        """Predict probabilities using the policy network."""
        return self.policy_net.forward(X).astype(np.float64)
