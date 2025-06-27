from typing import Any

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings using Pydantic Settings for 2025 best practices."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        case_sensitive=False,
        validate_assignment=True,
        extra="ignore",
    )

    # Discord Configuration
    discord_token: str = Field(description="Discord bot token")
    discord_guild_id: int | None = Field(None, description="Primary Discord guild ID")
    discord_registration_channel_name: str = Field(
        description="Registration channel name"
    )
    discord_test_channel_name: str = Field(description="Test channel name")
    discord_admin_role_id: int | None = Field(None, description="Admin role ID")

    # Bot Configuration
    command_prefix: str = Field("!", description="Bot command prefix")

    # Database Configuration
    database_url: str = Field(
        "sqlite+aiosqlite:///bot.db", description="Database connection URL"
    )
    database_echo: bool = Field(False, description="Enable SQLAlchemy query logging")

    # Google Sheets Configuration
    google_credentials_path: str = Field(
        "", description="Path to Google service account credentials"
    )
    google_spreadsheet_id: str = Field("", description="Google Sheets spreadsheet ID")

    # Environment and Logging
    environment: str = Field("development", description="Application environment")
    log_level: str = Field("INFO", description="Logging level")

    # Sentry Configuration (Optional)
    sentry_dsn: str = Field("", description="Sentry DSN for error tracking")

    @field_validator("discord_token")
    @classmethod
    def validate_discord_token(cls, v: str) -> str:
        """Validate Discord token format."""
        if not v:
            raise ValueError("Discord token is required")
        # Accept Bot prefix or realistic token length (50+ characters)
        if not (v.startswith("Bot ") or len(v) >= 50):
            raise ValueError("Invalid Discord token format")
        return v

    @field_validator("log_level")
    @classmethod
    def validate_log_level(cls, v: str) -> str:
        """Validate log level."""
        valid_levels = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
        if v.upper() not in valid_levels:
            raise ValueError(f"Log level must be one of {valid_levels}")
        return v.upper()

    @field_validator("environment")
    @classmethod
    def validate_environment(cls, v: str) -> str:
        """Validate environment."""
        valid_envs = {"development", "testing", "staging", "production"}
        if v.lower() not in valid_envs:
            raise ValueError(f"Environment must be one of {valid_envs}")
        return v.lower()


# Settings factory function
def get_settings(**kwargs: Any) -> Settings:
    """Get a settings instance with optional overrides."""
    return Settings(**kwargs)


# For testing, you can create isolated settings with:
# settings = get_settings(_env_file=None)
