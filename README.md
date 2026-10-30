# docker-env

Shared Docker infrastructure for local development. Run these services once
and reuse them from any project, instead of duplicating them in every
`docker-compose.yml`.

## Services

| Service | Purpose | URL / Port |
|---|---|---|
| `ollama` | Local LLM server | http://localhost:11434 |
| `ollama-init` | One-shot job that pulls the configured models, then exits | n/a |
| `chromadb` | Vector database | Host: http://localhost:8001 / Network: http://chromadb:8000 |
| `jaeger` | Distributed tracing UI and OTLP collector | UI: http://localhost:16686 |

OTLP endpoints: HTTP `4318`, gRPC `4317`.

## Quick start

```bash
cp .env.example .env
docker compose up -d
docker logs -f ollama-init     # follow the model downloads
```

Or with Make: `make up`.

## Configuration

Edit `.env`:

| Variable | Default | Description |
|---|---|---|
| `OLLAMA_MODELS_TO_PULL` | `llama3 nomic-embed-text` | Space-separated list of models pulled on startup |
| `CHROMA_VERSION` | `latest` | ChromaDB image tag |
| `CHROMA_HOST_PORT` | `8001` | Host port mapped to Chroma's port 8000 |

Models are stored in the `ollama_data` volume and persist across restarts.
Pulling is idempotent: existing models are only checked for updates.

## Using it from another project

All services join the external network `docker-env-net`. In your project's
`docker-compose.yml`:

```yaml
services:
  app:
    environment:
      OLLAMA_BASE_URL: http://ollama:11434
      OTEL_EXPORTER_ENDPOINT: http://jaeger:4318/v1/traces
      CHROMA_HOST: chromadb
      CHROMA_PORT: "8000"        # container port, not the host port 8001
    networks:
      - shared

networks:
  shared:
    name: docker-env-net
    external: true
```

Inside the network, use service names (`ollama`, `jaeger`), not `localhost`.

> Start `docker-env` **before** your projects, otherwise the external network
> does not exist yet.

## Commands

| Command | Description |
|---|---|
| `make up` | Start all services |
| `make down` | Stop all services (volumes are kept) |
| `make logs` | Follow the logs |
| `make models` | List the installed Ollama models |
| `make status` | Show container status |

## Troubleshooting

- **Port already in use:** another process uses 11434, 4318 or 16686.
- **`ollama-init` exited with code 1:** wrong model name or no disk space. Check `docker logs ollama-init`.
- **Network not found in another project:** run `docker compose up -d` here first.

## License

MIT