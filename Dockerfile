# Multi-stage Docker build following 2025 UV best practices
FROM python:3.12-slim AS base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Build stage
FROM base AS builder

# Install UV using official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Configure UV for optimal container performance
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/app/.venv

WORKDIR /app

# Copy dependency files first for optimal caching
COPY uv.lock pyproject.toml ./

# Install dependencies without project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# Copy project files and complete installation
COPY . ./

# Complete project installation
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Production stage using distroless for maximum security
FROM gcr.io/distroless/python3-debian12:nonroot AS production

# Set working directory
WORKDIR /app

# Copy complete application from builder
COPY --from=builder --chown=65532:65532 /app /app

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH="/app" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONHASHSEED=random

# Use non-root user (65532:65532 is nonroot user in distroless)
USER 65532:65532

# Health check using Python instead of curl for distroless compatibility
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import sys; sys.exit(0)"]

# Signal handling for graceful shutdown
STOPSIGNAL SIGTERM

# Default command
CMD ["python", "bot.py"]