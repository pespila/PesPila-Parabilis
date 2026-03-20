"""Tests for the data pipeline."""


from pespila.data.db import DatabaseManager
from pespila.data.registry import (
    build_csv_url,
    get_all_countries,
    get_all_seasons,
    season_label,
    season_years,
)


class TestRegistry:
    def test_all_seasons_count(self):
        seasons = get_all_seasons()
        assert len(seasons) == 33  # 93/94 through 25/26

    def test_season_label(self):
        assert season_label("9394") == "93/94"
        assert season_label("0102") == "01/02"
        assert season_label("2526") == "25/26"

    def test_season_years(self):
        assert season_years("9394") == (1993, 1994)
        assert season_years("0102") == (2001, 2002)
        assert season_years("2526") == (2025, 2026)

    def test_build_csv_url(self):
        url = build_csv_url("2324", "E0")
        assert "mmz4281/2324/E0.csv" in url

    def test_countries(self):
        countries = get_all_countries()
        assert "England" in countries
        assert "Germany" in countries
        assert len(countries) == 11


class TestDatabaseManager:
    def test_create_schema(self, db_path):
        with DatabaseManager(db_path) as db:
            db.create_schema()
            tables = db.fetchall(
                "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
            )
            table_names = {r["name"] for r in tables}
            assert "matches" in table_names
            assert "teams" in table_names
            assert "countries" in table_names

    def test_get_or_create_team(self, db_path):
        with DatabaseManager(db_path) as db:
            db.create_schema()
            id1 = db.get_or_create_team("Bayern Munich")
            id2 = db.get_or_create_team("Bayern Munich")
            id3 = db.get_or_create_team("Dortmund")
            assert id1 == id2
            assert id1 != id3

    def test_get_or_create_season(self, db_path):
        with DatabaseManager(db_path) as db:
            db.create_schema()
            id1 = db.get_or_create_season("15/16", 2015, 2016)
            id2 = db.get_or_create_season("15/16", 2015, 2016)
            assert id1 == id2
