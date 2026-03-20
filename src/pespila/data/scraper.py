"""Async scraper for football-data.co.uk CSV files."""

from __future__ import annotations

import asyncio
import io
import logging

import httpx
import polars as pl

from pespila.data.registry import BASE_URL, LEAGUE_REGISTRY, LeagueInfo, get_all_seasons

logger = logging.getLogger(__name__)

# Columns we always try to extract (older seasons may lack some)
CORE_COLUMNS = ["Div", "Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG", "FTR", "HTHG", "HTAG", "HTR"]
ODDS_COLUMNS = ["B365H", "B365D", "B365A"]


class FootballDataScraper:
    """Downloads and parses CSV match data from football-data.co.uk."""

    def __init__(
        self,
        max_concurrent: int = 5,
        rate_limit_delay: float = 0.2,
    ) -> None:
        self.max_concurrent = max_concurrent
        self.rate_limit_delay = rate_limit_delay

    async def fetch_csv(
        self,
        client: httpx.AsyncClient,
        season_code: str,
        league: LeagueInfo,
        semaphore: asyncio.Semaphore,
    ) -> tuple[LeagueInfo, str, pl.DataFrame | None]:
        """Fetch a single CSV and return as a polars DataFrame."""
        url = f"{BASE_URL}/{season_code}/{league.league_code}.csv"
        async with semaphore:
            try:
                resp = await client.get(url)
                if resp.status_code == 404:
                    return league, season_code, None
                resp.raise_for_status()
                await asyncio.sleep(self.rate_limit_delay)

                text = resp.text.strip()
                if not text:
                    return league, season_code, None

                df = pl.read_csv(io.StringIO(text), infer_schema_length=0, truncate_ragged_lines=True)

                # Normalize column names (strip whitespace)
                df = df.rename({c: c.strip() for c in df.columns})

                # Keep only rows that have actual data
                if "HomeTeam" in df.columns:
                    df = df.filter(pl.col("HomeTeam").is_not_null() & (pl.col("HomeTeam") != ""))
                elif "Home" in df.columns:
                    df = df.rename({"Home": "HomeTeam", "Away": "AwayTeam"})
                    df = df.filter(pl.col("HomeTeam").is_not_null() & (pl.col("HomeTeam") != ""))

                return league, season_code, df

            except httpx.HTTPStatusError:
                logger.warning("HTTP error fetching %s/%s", season_code, league.league_code)
                return league, season_code, None
            except Exception as e:
                logger.warning(
                    "Error fetching %s/%s: %s", season_code, league.league_code, e
                )
                return league, season_code, None

    async def scrape_all(
        self,
        countries: list[str] | None = None,
        seasons: list[str] | None = None,
    ) -> list[tuple[LeagueInfo, str, pl.DataFrame]]:
        """Scrape all available CSVs. Returns list of (league_info, season_code, dataframe)."""
        leagues = LEAGUE_REGISTRY
        if countries:
            country_set = set(countries)
            leagues = [lg for lg in leagues if lg.country in country_set]

        all_seasons = seasons or get_all_seasons()
        semaphore = asyncio.Semaphore(self.max_concurrent)
        results: list[tuple[LeagueInfo, str, pl.DataFrame]] = []

        async with httpx.AsyncClient(
            timeout=httpx.Timeout(30.0),
            follow_redirects=True,
            headers={"User-Agent": "PesPila-Parabilis/0.1.0"},
        ) as client:
            tasks = [
                self.fetch_csv(client, season, league, semaphore)
                for season in all_seasons
                for league in leagues
            ]
            for coro in asyncio.as_completed(tasks):
                league, season_code, df = await coro
                if df is not None and len(df) > 0:
                    logger.info(
                        "Fetched %s %s: %d matches",
                        league.league_code,
                        season_code,
                        len(df),
                    )
                    results.append((league, season_code, df))

        return results

    def scrape_all_sync(
        self,
        countries: list[str] | None = None,
        seasons: list[str] | None = None,
    ) -> list[tuple[LeagueInfo, str, pl.DataFrame]]:
        """Synchronous wrapper for scrape_all."""
        return asyncio.run(self.scrape_all(countries=countries, seasons=seasons))
