"""Database manager with context manager support."""

from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any

import pandas as pd

from pespila.data.schema import SCHEMA_SQL
from pespila.exceptions import SchemaError


class DatabaseManager:
    """SQLite database manager with connection pooling and schema management."""

    def __init__(self, db_path: str | Path = "data/pespila.db") -> None:
        self.db_path = Path(db_path)
        self._conn: sqlite3.Connection | None = None

    @property
    def conn(self) -> sqlite3.Connection:
        if self._conn is None:
            raise SchemaError("Database not connected. Use as context manager.")
        return self._conn

    def __enter__(self) -> DatabaseManager:
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn = sqlite3.connect(str(self.db_path))
        self._conn.execute("PRAGMA journal_mode=WAL")
        self._conn.execute("PRAGMA foreign_keys=ON")
        self._conn.row_factory = sqlite3.Row
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        if self._conn is not None:
            self._conn.close()
            self._conn = None

    def create_schema(self) -> None:
        self.conn.executescript(SCHEMA_SQL)
        self.conn.commit()

    def execute(self, sql: str, params: tuple[Any, ...] = ()) -> sqlite3.Cursor:
        return self.conn.execute(sql, params)

    def executemany(self, sql: str, params_seq: list[tuple[Any, ...]]) -> sqlite3.Cursor:
        return self.conn.executemany(sql, params_seq)

    def fetchone(self, sql: str, params: tuple[Any, ...] = ()) -> sqlite3.Row | None:
        return self.conn.execute(sql, params).fetchone()

    def fetchall(self, sql: str, params: tuple[Any, ...] = ()) -> list[sqlite3.Row]:
        return self.conn.execute(sql, params).fetchall()

    def to_dataframe(self, sql: str, params: tuple[Any, ...] = ()) -> pd.DataFrame:
        return pd.read_sql_query(sql, self.conn, params=params)

    def commit(self) -> None:
        self.conn.commit()

    def get_or_create_team(self, name: str) -> int:
        row = self.fetchone("SELECT team_id FROM teams WHERE name = ?", (name,))
        if row:
            return row["team_id"]
        cursor = self.execute("INSERT INTO teams (name) VALUES (?)", (name,))
        self.commit()
        return cursor.lastrowid  # type: ignore[return-value]

    def get_or_create_country(self, name: str, code: str) -> int:
        row = self.fetchone("SELECT country_id FROM countries WHERE code = ?", (code,))
        if row:
            return row["country_id"]
        cursor = self.execute(
            "INSERT INTO countries (name, code) VALUES (?, ?)", (name, code)
        )
        self.commit()
        return cursor.lastrowid  # type: ignore[return-value]

    def get_or_create_league(self, country_id: int, name: str, code: str, tier: int = 1) -> int:
        row = self.fetchone("SELECT league_id FROM leagues WHERE code = ?", (code,))
        if row:
            return row["league_id"]
        cursor = self.execute(
            "INSERT INTO leagues (country_id, name, code, tier) VALUES (?, ?, ?, ?)",
            (country_id, name, code, tier),
        )
        self.commit()
        return cursor.lastrowid  # type: ignore[return-value]

    def get_or_create_season(self, label: str, year_start: int, year_end: int) -> int:
        row = self.fetchone("SELECT season_id FROM seasons WHERE label = ?", (label,))
        if row:
            return row["season_id"]
        cursor = self.execute(
            "INSERT INTO seasons (label, year_start, year_end) VALUES (?, ?, ?)",
            (label, year_start, year_end),
        )
        self.commit()
        return cursor.lastrowid  # type: ignore[return-value]
