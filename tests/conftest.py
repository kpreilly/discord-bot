"""Shared pytest fixtures and test utilities."""

import pytest


class TestDataFactory:
    """Factory for test data generation."""

    @staticmethod
    def discord_token(valid: bool = True) -> str:
        """Generate a Discord token for testing."""
        if valid:
            # Generate a clearly fake test token that won't trigger security scanning
            return "TEST_TOKEN_" + "x" * 60  # 70+ chars, clearly fake
        else:
            return "invalid_token"

    @staticmethod
    def bot_token() -> str:
        """Generate a Bot-prefixed token for testing."""
        return f"Bot {TestDataFactory.discord_token()}"

    @staticmethod
    def discord_id() -> int:
        """Generate a Discord ID for testing."""
        return 123456789012345678

    @staticmethod
    def guild_id() -> int:
        """Generate a Discord guild ID for testing."""
        return 987654321098765432


@pytest.fixture
def clean_env(monkeypatch):
    """Clear all environment variables that might affect settings."""
    env_vars = [
        "DISCORD_TOKEN",
        "DISCORD_GUILD_ID",
        "DISCORD_REGISTRATION_CHANNEL_NAME",
        "DISCORD_TEST_CHANNEL_NAME",
        "DISCORD_ADMIN_ROLE_ID",
        "COMMAND_PREFIX",
        "DATABASE_URL",
        "DATABASE_ECHO",
        "ENVIRONMENT",
        "LOG_LEVEL",
        "GOOGLE_CREDENTIALS_PATH",
        "GOOGLE_SPREADSHEET_ID",
        "SENTRY_DSN",
    ]
    for var in env_vars:
        monkeypatch.delenv(var, raising=False)


@pytest.fixture
def minimal_config(clean_env, monkeypatch):
    """Set up minimal valid configuration."""
    monkeypatch.setenv("DISCORD_TOKEN", TestDataFactory.discord_token())
    monkeypatch.setenv("DISCORD_REGISTRATION_CHANNEL_NAME", "registrations")
    monkeypatch.setenv("DISCORD_TEST_CHANNEL_NAME", "testing")


@pytest.fixture
def test_data_factory():
    """Provide access to test data factory."""
    return TestDataFactory
