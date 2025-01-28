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

