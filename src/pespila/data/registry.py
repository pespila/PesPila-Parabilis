"""Country/league/season URL mappings for football-data.co.uk."""

from __future__ import annotations

from dataclasses import dataclass

BASE_URL = "https://www.football-data.co.uk/mmz4281"


@dataclass(frozen=True)
class LeagueInfo:
    country: str
    country_code: str
    league_name: str
    league_code: str
    tier: int


LEAGUE_REGISTRY: list[LeagueInfo] = [
    # Belgium
    LeagueInfo("Belgium", "BEL", "Jupiler League", "B1", 1),
    # England
    LeagueInfo("England", "ENG", "Premier League", "E0", 1),
    LeagueInfo("England", "ENG", "Championship", "E1", 2),
    LeagueInfo("England", "ENG", "League One", "E2", 3),
    LeagueInfo("England", "ENG", "League Two", "E3", 4),
    LeagueInfo("England", "ENG", "Conference", "EC", 5),
    # France
    LeagueInfo("France", "FRA", "Ligue 1", "F1", 1),
    LeagueInfo("France", "FRA", "Ligue 2", "F2", 2),
    # Germany
    LeagueInfo("Germany", "GER", "Bundesliga", "D1", 1),
    LeagueInfo("Germany", "GER", "2. Bundesliga", "D2", 2),
    # Greece
    LeagueInfo("Greece", "GRE", "Super League", "G1", 1),
    # Italy
    LeagueInfo("Italy", "ITA", "Serie A", "I1", 1),
    LeagueInfo("Italy", "ITA", "Serie B", "I2", 2),
    # Netherlands
    LeagueInfo("Netherlands", "NED", "Eredivisie", "N1", 1),
    # Portugal
    LeagueInfo("Portugal", "POR", "Liga I", "P1", 1),
    # Scotland
    LeagueInfo("Scotland", "SCO", "Premiership", "SC0", 1),
    LeagueInfo("Scotland", "SCO", "Championship", "SC1", 2),
    LeagueInfo("Scotland", "SCO", "League One", "SC2", 3),
    LeagueInfo("Scotland", "SCO", "League Two", "SC3", 4),
    # Spain
    LeagueInfo("Spain", "ESP", "La Liga", "SP1", 1),
    LeagueInfo("Spain", "ESP", "La Liga 2", "SP2", 2),
    # Turkey
    LeagueInfo("Turkey", "TUR", "Super Lig", "T1", 1),
]


def get_all_seasons() -> list[str]:
    """Generate season codes from 93/94 through 25/26."""
    seasons = []
    for start_year in range(93, 100):
        end_year = start_year + 1
        seasons.append(f"{start_year:02d}{end_year:02d}")
    for start_year in range(0, 26):
        end_year = start_year + 1
        seasons.append(f"{start_year:02d}{end_year:02d}")
    return seasons


def season_label(code: str) -> str:
    """Convert season code to display label: '9394' -> '93/94', '0102' -> '01/02'."""
    return f"{code[:2]}/{code[2:]}"


def season_years(code: str) -> tuple[int, int]:
    """Convert season code to (year_start, year_end)."""
    start = int(code[:2])
    end = int(code[2:])
    start_full = 1900 + start if start >= 90 else 2000 + start
    end_full = 1900 + end if end >= 90 else 2000 + end
    return start_full, end_full


def build_csv_url(season_code: str, league_code: str) -> str:
    """Build the CSV download URL."""
    return f"{BASE_URL}/{season_code}/{league_code}.csv"


def get_leagues_for_country(country: str) -> list[LeagueInfo]:
    """Get all leagues for a given country."""
    return [lg for lg in LEAGUE_REGISTRY if lg.country == country]


def get_all_countries() -> list[str]:
    """Get unique country names."""
    seen: set[str] = set()
    result: list[str] = []
    for lg in LEAGUE_REGISTRY:
        if lg.country not in seen:
            seen.add(lg.country)
            result.append(lg.country)
    return result
