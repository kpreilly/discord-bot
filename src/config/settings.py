from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings using Pydantic Settings for 2025 best practices."""
    
    # Discord Configuration
    discord_token: str = Field(..., env="DISCORD_TOKEN")
    discord_guild_id: int = Field(..., env="DISCORD_GUILD_ID")
    discord_registration_channel_id: int = Field(..., env="DISCORD_REGISTRATION_CHANNEL_ID")
    discord_admin_role_id: int = Field(..., env="DISCORD_ADMIN_ROLE_ID")
    
    # Bot Configuration
    command_prefix: str = Field("!", env="COMMAND_PREFIX")
    
    # Database Configuration
    database_url: str = Field("sqlite+aiosqlite:///bot.db", env="DATABASE_URL")
    database_echo: bool = Field(False, env="DATABASE_ECHO")
    
    # Google Sheets Configuration
    google_credentials_path: str = Field("", env="GOOGLE_CREDENTIALS_PATH")
    google_spreadsheet_id: str = Field("", env="GOOGLE_SPREADSHEET_ID")
    
    # Environment and Logging
    environment: str = Field("development", env="ENVIRONMENT")
    log_level: str = Field("INFO", env="LOG_LEVEL")
    
    # Sentry Configuration (Optional)
    sentry_dsn: str = Field("", env="SENTRY_DSN")
    
    class Config:
        env_file = ".env"
        env_ignore_empty = True
        case_sensitive = False


# Global settings instance
settings = Settings()