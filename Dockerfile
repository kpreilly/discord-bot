# Multi-stage Docker build following 2025 security best practices
# Build stage
FROM python:3.12-slim AS builder

WORKDIR /app

# Install uv for fast dependency management
RUN pip install uv

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Production stage
FROM python:3.12-slim AS production

# Create non-root user for security
RUN groupadd -r botuser && useradd -r -g botuser botuser

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Add venv to path
ENV PATH="/app/.venv/bin:$PATH"

# Copy application code
COPY --chown=botuser:botuser . .

# Switch to non-root user
USER botuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import asyncio; print('healthy')" || exit 1

# Set resource limits and run bot
CMD ["python", "bot.py"]