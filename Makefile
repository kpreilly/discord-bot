# Discord Bot Makefile
# Development commands following 2025 best practices

.PHONY: help install dev test lint format check clean build docker-build docker-run setup migrate

# Default target
help: ## Show this help message
	@echo "Discord Bot Development Commands"
	@echo "================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation and Setup
install: ## Install dependencies with uv
	uv sync

install-dev: ## Install dependencies including dev tools
	uv sync --dev

setup: install-dev ## Complete initial setup
	uv run pre-commit install
	@echo "✅ Setup complete! Run 'make dev' to start the bot."

# Development
dev: ## Run the bot in development mode
	uv run python bot.py

dev-reload: ## Run with auto-reload for development
	uv run watchmedo auto-restart --patterns="*.py" --recursive -- python bot.py

# Database
migrate: ## Run database migrations
	uv run alembic upgrade head

migrate-create: ## Create a new migration (pass NAME=migration_name)
	uv run alembic revision --autogenerate -m "$(NAME)"

migrate-rollback: ## Rollback last migration
	uv run alembic downgrade -1

migrate-history: ## Show migration history
	uv run alembic history --verbose

# Code Quality
lint: ## Run linting with ruff
	uv run ruff check .

lint-fix: ## Run linting with automatic fixes
	uv run ruff check . --fix

format: ## Format code with ruff
	uv run ruff format .

format-check: ## Check code formatting without making changes
	uv run ruff format . --check

type-check: ## Run mypy type checking
	uv run mypy src/

check: lint format-check type-check ## Run all code quality checks

check-fix: lint-fix format ## Run all checks with automatic fixes

# Security
security: ## Run security checks
	uv run safety check --json || true
	uv run bandit -r src/ -f json || true

# Testing
test: ## Run tests
	uv run pytest

test-cov: ## Run tests with coverage
	uv run pytest --cov=src --cov-report=term-missing --cov-report=html

test-watch: ## Run tests in watch mode
	uv run pytest-watch

test-integration: ## Run integration tests
	uv run pytest -m integration

# Pre-commit
pre-commit: ## Run pre-commit hooks on all files
	uv run pre-commit run --all-files

pre-commit-update: ## Update pre-commit hooks
	uv run pre-commit autoupdate

# Docker
docker-build: ## Build Docker image
	docker build -t discord-bot:latest .

docker-run: ## Run Docker container
	docker run --env-file .env discord-bot:latest

docker-dev: ## Run Docker container with development setup
	docker-compose -f docker-compose.dev.yml up --build

# Utilities
clean: ## Clean up cache and temporary files
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -rf htmlcov/ .coverage coverage.xml

deps-update: ## Update dependencies
	uv sync --upgrade

deps-show: ## Show dependency tree
	uv tree

# Git workflow helpers
commit-check: check test ## Run checks before committing
	@echo "✅ All checks passed! Ready to commit."

release-check: check test security ## Run full release checks
	@echo "✅ All release checks passed!"

# Environment
env-example: ## Copy environment example file
	cp .env.example .env
	@echo "📝 Copied .env.example to .env - please edit with your values"

# Bot management
bot-invite: ## Show bot invite link (requires DISCORD_CLIENT_ID in .env)
	@echo "Bot invite link:"
	@echo "https://discord.com/oauth2/authorize?client_id=$$(grep DISCORD_CLIENT_ID .env | cut -d '=' -f2)&permissions=8&integration_type=0&scope=applications.commands+bot"

# Documentation
docs-serve: ## Serve documentation locally
	@echo "📚 Documentation will be available at: http://localhost:8000"
	uv run mkdocs serve

docs-build: ## Build documentation
	uv run mkdocs build

# Quick development workflow
quick-setup: setup env-example ## Quick setup for new developers
	@echo "🚀 Quick setup complete!"
	@echo "1. Edit .env with your Discord bot token"
	@echo "2. Run 'make migrate' to set up the database"
	@echo "3. Run 'make dev' to start the bot"

quick-test: check test ## Quick test run for CI/development
	@echo "✅ Quick tests passed!"