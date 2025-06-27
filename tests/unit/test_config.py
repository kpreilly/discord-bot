"""Tests for configuration settings."""

import pytest
from pydantic import ValidationError

from src.config.settings import Settings, get_settings


def test_settings_factory(clean_env):
    """Test that settings factory works properly."""
    settings = get_settings(
        discord_token="TEST_TOKEN_" + "x" * 60,
        discord_registration_channel_name="registrations",
        discord_test_channel_name="testing"
    )
    assert isinstance(settings, Settings)
    assert settings.discord_token == "TEST_TOKEN_" + "x" * 60
    assert settings.discord_registration_channel_name == "registrations"


def test_settings_with_minimal_config(minimal_config):
    """Test settings with minimal valid configuration."""
    settings = get_settings()
    assert settings.discord_token == "TEST_TOKEN_" + "x" * 60
    assert settings.discord_registration_channel_name == "registrations"
    assert settings.discord_test_channel_name == "testing"
    assert settings.command_prefix == "!"
    assert settings.environment == "development"
    assert settings.log_level == "INFO"


def test_discord_token_validation_valid_token(clean_env, test_data_factory):
    """Test that valid Discord tokens pass validation."""
    valid_token = test_data_factory.discord_token()
    settings = get_settings(
        discord_token=valid_token,
        discord_registration_channel_name="registrations",
        discord_test_channel_name="testing"
    )
    assert settings.discord_token == valid_token


def test_discord_token_validation_bot_prefix(clean_env, test_data_factory):
    """Test that Bot-prefixed tokens pass validation."""
    bot_token = test_data_factory.bot_token()
    settings = get_settings(
        discord_token=bot_token,
        discord_registration_channel_name="registrations",
        discord_test_channel_name="testing"
    )
    assert settings.discord_token == bot_token


def test_discord_token_validation_invalid_token(clean_env, test_data_factory):
    """Test that invalid Discord tokens fail validation."""
    invalid_token = test_data_factory.discord_token(valid=False)
    
    with pytest.raises(ValidationError) as exc_info:
        get_settings(
            discord_token=invalid_token,
            discord_registration_channel_name="registrations",
            discord_test_channel_name="testing"
        )
    
    assert "Invalid Discord token format" in str(exc_info.value)


def test_discord_token_validation_empty_token(clean_env):
    """Test that empty Discord token fails validation."""
    with pytest.raises(ValidationError) as exc_info:
        get_settings(
            discord_token="",
            discord_registration_channel_name="registrations",
            discord_test_channel_name="testing"
        )
    
    assert "Discord token is required" in str(exc_info.value)


def test_log_level_validation_valid(clean_env, test_data_factory):
    """Test that valid log levels pass validation."""
    for level in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
        settings = get_settings(
            discord_token=test_data_factory.discord_token(),
            discord_registration_channel_name="registrations",
            discord_test_channel_name="testing",
            log_level=level
        )
        assert settings.log_level == level


def test_log_level_validation_case_insensitive(clean_env, test_data_factory):
    """Test that log level validation is case insensitive."""
    settings = get_settings(
        discord_token=test_data_factory.discord_token(),
        discord_registration_channel_name="registrations",
        discord_test_channel_name="testing",
        log_level="debug"
    )
    assert settings.log_level == "DEBUG"


def test_log_level_validation_invalid(clean_env, test_data_factory):
    """Test that invalid log levels fail validation."""
    with pytest.raises(ValidationError) as exc_info:
        get_settings(
            discord_token=test_data_factory.discord_token(),
            discord_registration_channel_name="registrations",
            discord_test_channel_name="testing",
            log_level="INVALID"
        )
    
    assert "Log level must be one of" in str(exc_info.value)


def test_environment_validation_valid(clean_env, test_data_factory):
    """Test that valid environments pass validation."""
    for env in ["development", "testing", "staging", "production"]:
        settings = get_settings(
            discord_token=test_data_factory.discord_token(),
            discord_registration_channel_name="registrations",
            discord_test_channel_name="testing",
            environment=env
        )
        assert settings.environment == env


def test_environment_validation_case_insensitive(clean_env, test_data_factory):
    """Test that environment validation is case insensitive."""
    settings = get_settings(
        discord_token=test_data_factory.discord_token(),
        discord_registration_channel_name="registrations",
        discord_test_channel_name="testing",
        environment="PRODUCTION"
    )
    assert settings.environment == "production"


def test_environment_validation_invalid(clean_env, test_data_factory):
    """Test that invalid environments fail validation."""
    with pytest.raises(ValidationError) as exc_info:
        get_settings(
            discord_token=test_data_factory.discord_token(),
            discord_registration_channel_name="registrations",
            discord_test_channel_name="testing",
            environment="invalid"
        )
    
    assert "Environment must be one of" in str(exc_info.value)


def test_optional_fields_defaults(clean_env, test_data_factory):
    """Test that optional fields have proper defaults."""
    settings = get_settings(
        discord_token=test_data_factory.discord_token(),
        discord_registration_channel_name="registrations",
        discord_test_channel_name="testing"
    )
    
    assert settings.discord_guild_id is None
    assert settings.discord_admin_role_id is None
    assert settings.command_prefix == "!"
    assert settings.database_url == "sqlite+aiosqlite:///bot.db"
    assert settings.database_echo is False
    assert settings.google_credentials_path == ""
    assert settings.google_spreadsheet_id == ""
    assert settings.environment == "development"
    assert settings.log_level == "INFO"
    assert settings.sentry_dsn == ""


def test_settings_isolation(clean_env, test_data_factory):
    """Test that different settings instances are isolated."""
    settings1 = get_settings(
        discord_token=test_data_factory.discord_token(),
        discord_registration_channel_name="registrations",
        discord_test_channel_name="testing",
        command_prefix="?"
    )
    
    settings2 = get_settings(
        discord_token=test_data_factory.discord_token(),
        discord_registration_channel_name="registrations",
        discord_test_channel_name="testing",
        command_prefix="!"
    )
    
    assert settings1.command_prefix == "?"
    assert settings2.command_prefix == "!"
    assert settings1 is not settings2