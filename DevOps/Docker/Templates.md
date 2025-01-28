
# Compose

```yaml
x-common: &common
  restart: unless-stopped
  networks:
    - app-network

x-postgres-variables: &postgres-variables
  DB_USER: "${DB_USER}"
  DB_PASSWORD: "/run/secrets/db_password"
  DB_NAME: "${DB_NAME}"
  DB_PORT: "${DB_PORT}"

x-pgadmin-variables: &pgadmin-variables
  PGADMIN_EMAIL: "${PGADMIN_EMAIL}"
  PGADMIN_PASSWORD: "/run/secrets/pgadmin_password"

x-resource-profiles:
  small: &small-profile
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 256M
        reservations:
          cpus: "0.1"
          memory: 128M
  medium: &medium-profile
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 512M
        reservations:
          cpus: "0.25"
          memory: 256M
  large: &large-profile
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 1G
        reservations:
          cpus: "0.5"
          memory: 512M

services:
  app:
    <<: [*common, *medium-profile]
    build:
      context: ../..
      dockerfile: deploy/dev/dev.Dockerfile
    container_name: ssl-generator-app
    env_file:
      - dev.env
    environment:
      DB_HOST: ssl-generator-db
      DB_USER: ${DB_USER}
      DB_PASSWORD_FILE: /run/secrets/db_password
      DB_NAME: ${DB_NAME}
      DB_PORT: ${DB_PORT}
      SENTRY_DSN: ${SENTRY_DSN}
      SENTRY_ENVIRONMENT: ${SENTRY_ENVIRONMENT}
      SENTRY_RELEASE: ${VERSION:-1.0.0}
      SENTRY_TRACES_SAMPLE_RATE: 0.5
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "8080:8080"

  postgres:
    <<: [*common, *large-profile]
    image: postgres:16
    container_name: ssl-generator-db
    env_file:
      - dev.env
    environment:
      <<: *postgres-variables
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${DB_USER} -d $${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d:ro
    ports:
      - "${DB_PORT}:5432"
    command: 
      - "postgres"
      - "-c"
      - "max_connections=100"
      - "-c"
      - "shared_buffers=256MB"

  pgadmin:
    <<: [*common, *small-profile]
    image: dpage/pgadmin4
    container_name: ssl-generator-pgadmin
    env_file:
      - dev.env
    environment:
      <<: *pgadmin-variables
      PGADMIN_CONFIG_CONSOLE_LOG_LEVEL: 30
    healthcheck:
      test: ["CMD", "wget", "-O", "-", "http://localhost:80/misc/ping"]
      interval: 60s
      timeout: 5s
      retries: 5
      start_period: 30s
    volumes:
      - pgadmin-data:/var/lib/pgadmin
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "${PGADMIN_PORT}:80"

volumes:
  pgdata:
    driver: local
  pgadmin-data:
    driver: local

networks:
  app-network:
    driver: bridge

secrets:
  db_password:
    external: true
  pgadmin_password:
    external: true
```





# Dockerfile

```dockerfile
FROM golang:1.23.4-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY ../../ ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o run-app ./cmd/app/main.go && \
    echo "Build successful!" || (echo "Build failed!" && exit 1)

# ---------------------------------------------------------------------------------------------------------------------------- #
FROM alpine:latest

WORKDIR /app

RUN apk add --no-cache \
    curl \
    bash \
    postgresql-client \
    ca-certificates

RUN adduser -D -u 1001 admin

COPY --from=builder /app/run-app /app/
COPY config/ /app/config/
COPY internal/storage/migrations /app/internal/storage/migrations/

RUN chown -R admin:admin /app

USER admin

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8080/healthcheck || exit 1

EXPOSE 8080

CMD ["/app/run-app"]
```

