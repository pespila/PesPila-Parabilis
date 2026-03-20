"""Number and date formatting utilities."""

from __future__ import annotations

from datetime import datetime


def format_percentage(value: float) -> str:
    """Format as percentage with 1 decimal."""
    return f"{value:.1f}%"


def format_odds(value: float) -> str:
    """Format betting odds."""
    if value == float("inf"):
        return "-"
    return f"{value:.2f}"


def format_date(date_str: str) -> str:
    """Format date for display."""
    try:
        dt = datetime.strptime(date_str, "%Y-%m-%d")
        return dt.strftime("%d %b %Y")
    except (ValueError, TypeError):
        return date_str or ""
