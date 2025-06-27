# Discord Bot for Rocket League Tracker Registration

A Discord bot for handling Rocket League tracker registration for competitive teams.

## Features

- `/register` command for tracker URL submission
- Tracker URL validation
- Private channel notifications for admin review
- Google Sheets integration
- Modular cog-based architecture

## Development

This project uses:
- Python with discord.py
- uv for dependency management
- ruff for linting/formatting
- pytest for testing
- Docker for containerization

## Getting Started

1. Install uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. Install dependencies: `uv sync`
3. Copy environment file: `cp .env.example .env`
4. Configure your Discord bot token and other settings
5. Run the bot: `make dev`

## Development Commands

- `make dev` - Run the bot in development mode
- `make test` - Run tests
- `make lint` - Run linting
- `make format` - Format code
- `make check` - Run all quality checks

## Project Structure

```
src/
├── cogs/           # Discord bot cogs
├── core/           # Core bot functionality
├── services/       # External service integrations
└── utils/          # Utility functions
tests/              # Test files
docker/             # Docker configurations
docs/               # Documentation
```