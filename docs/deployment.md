# Discord Bot Deployment Guide

This guide covers deploying the Discord bot using Docker and Compose v2 following 2025 security best practices.

## Prerequisites

- Docker Engine 24.0+ with Compose v2
- Git for source code management
- Discord Bot Token (from Discord Developer Portal)

## Quick Start

### Development Environment

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd discord_bot
   ```

2. **Configure secrets:**
   ```bash
   # Replace placeholder tokens with real values
   echo "YOUR_DISCORD_BOT_TOKEN" > secrets/dev/discord_token.txt
   ```

3. **Start development environment:**
   ```bash
   COMPOSE_ENV=dev docker compose -f compose.yml -f compose.dev.yml up -d
   ```

4. **View logs:**
   ```bash
   docker compose logs -f discord-bot
   ```

## Environment Management

### Available Environments

- **Development** (`dev`): Local development with hot reloading and debug logging
- **Testing** (`test`): Automated testing environment with coverage reporting
- **Production** (`prod`): Production-ready with monitoring and optimized resources

### Environment Commands

```bash
# Development
COMPOSE_ENV=dev docker compose -f compose.yml -f compose.dev.yml up -d

# Testing
COMPOSE_ENV=test docker compose -f compose.yml -f compose.test.yml up -d

# Production
COMPOSE_ENV=prod docker compose -f compose.yml -f compose.prod.yml up -d
```

## Secrets Management

### Development and Testing

Secrets are managed through local files in the `secrets/` directory:

```
secrets/
├── dev/
│   ├── discord_token.txt
│   ├── database_url.txt
│   └── db_password.txt
├── test/
│   ├── discord_token.txt
│   ├── database_url.txt
│   └── db_password.txt
└── prod/
    └── (external secrets - see production section)
```

### Production Secrets

Production uses external Docker secrets for enhanced security:

```bash
# Create external secrets
echo "PRODUCTION_DISCORD_TOKEN" | docker secret create discord_token_prod -
echo "PRODUCTION_DB_PASSWORD" | docker secret create db_password_prod -
echo "postgresql+asyncpg://user:pass@host:5432/db" | docker secret create database_url_prod -
```

## Security Features

### Container Security

- **Distroless base image**: Minimal attack surface with no shell access
- **Non-root user**: All processes run as unprivileged user (65532:65532)
- **Read-only filesystem**: Container filesystem is read-only with specific writable tmpfs mounts
- **Resource limits**: CPU and memory limits prevent resource exhaustion
- **Health checks**: Automated container health monitoring

### Network Security

- **Network isolation**: Separate networks for frontend and database communication
- **Internal database network**: Database not exposed to external networks
- **Minimal port exposure**: Only necessary ports exposed to host

### Secrets Security

- **No secrets in environment variables**: All sensitive data passed via Docker secrets
- **File-based secrets**: Secrets mounted as files in `/run/secrets/`
- **External secret management**: Production secrets managed externally
- **Proper file permissions**: Secret files have restricted access

## Monitoring and Observability

### Development Monitoring

```bash
# View container status
docker compose ps

# Monitor resource usage
docker stats

# View logs with timestamps
docker compose logs -f --timestamps
```

### Production Monitoring

Production environment includes Prometheus and Grafana:

- **Prometheus**: `http://localhost:9090` - Metrics collection
- **Grafana**: `http://localhost:3000` - Metrics visualization
- **Default credentials**: Configure via `grafana_admin_password` secret

### Health Checks

All services include health checks:

```bash
# Check service health
docker compose ps
docker inspect <container_name> | jq '.[0].State.Health'
```

## Troubleshooting

### Common Issues

1. **Permission denied errors:**
   ```bash
   # Ensure proper ownership of secrets
   chmod 600 secrets/*/
   ```

2. **Database connection failures:**
   ```bash
   # Check database container logs
   docker compose logs database
   
   # Verify database is healthy
   docker compose exec database pg_isready -U $DB_USER
   ```

3. **Discord connection issues:**
   ```bash
   # Verify token is valid
   docker compose logs discord-bot | grep -i discord
   ```

### Container Debugging

```bash
# Access container for debugging (development only)
docker compose exec discord-bot /bin/sh

# View container processes
docker compose exec discord-bot ps aux

# Check container resource usage
docker stats discord-bot
```

## Backup and Recovery

### Database Backups

```bash
# Create database backup
docker compose exec database pg_dump -U $DB_USER $DB_NAME > backup.sql

# Restore from backup
docker compose exec -T database psql -U $DB_USER $DB_NAME < backup.sql
```

### Configuration Backups

```bash
# Backup entire configuration
tar -czf discord-bot-backup.tar.gz \
  compose*.yml \
  .env.* \
  secrets/ \
  docs/
```

## Performance Optimization

### Resource Tuning

1. **Memory limits**: Adjust based on bot usage patterns
2. **CPU limits**: Scale based on command processing requirements
3. **Database resources**: Tune PostgreSQL settings for workload

### Image Optimization

```bash
# Check image size
docker images discord-bot

# Analyze image layers
docker history discord-bot:latest

# Security scan
docker scout cves discord-bot:latest
```

## Scaling Considerations

### Horizontal Scaling

For high-traffic bots, consider:

1. **Multiple bot instances**: Load balance across Discord shards
2. **Database read replicas**: Separate read/write database operations
3. **External caching**: Redis for session management

### Migration to Kubernetes

If scaling beyond single-host deployment:

1. Convert Compose files to Kubernetes manifests
2. Implement Kubernetes secrets management
3. Use Helm charts for deployment management
4. Consider service mesh (Istio/Linkerd) for complex networking

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Discord Bot
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and deploy
        run: |
          docker compose build
          docker compose -f compose.yml -f compose.prod.yml up -d
```

### Security Scanning

```bash
# Automated security scanning
docker scout cves discord-bot:latest
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image discord-bot:latest
```

## Production Deployment Checklist

- [ ] Configure production secrets externally
- [ ] Set up monitoring and alerting
- [ ] Configure log aggregation
- [ ] Implement automated backups
- [ ] Set up SSL/TLS certificates
- [ ] Configure firewall rules
- [ ] Test disaster recovery procedures
- [ ] Document operational runbooks

## Support and Maintenance

### Regular Maintenance Tasks

1. **Security updates**: Update base images monthly
2. **Dependency updates**: Update Python packages regularly
3. **Log rotation**: Configure log retention policies
4. **Secret rotation**: Rotate sensitive credentials quarterly
5. **Backup verification**: Test backup restoration procedures

### Getting Help

- Check container logs: `docker compose logs`
- Review health checks: `docker compose ps`
- Monitor resource usage: `docker stats`
- Consult troubleshooting section above

For additional support, create an issue in the project repository with:
- Environment details
- Error messages
- Container logs
- Steps to reproduce