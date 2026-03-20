"""PesPila exception hierarchy."""


class PesPilaError(Exception):
    """Base exception for all PesPila errors."""


class DataError(PesPilaError):
    """Raised for data acquisition or processing failures."""


class FittingError(PesPilaError):
    """Raised when distribution fitting fails to converge."""


class PredictionError(PesPilaError):
    """Raised when prediction cannot be computed."""


class SchemaError(PesPilaError):
    """Raised for database schema issues."""
