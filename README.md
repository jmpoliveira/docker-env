# docker-env

Shared Docker infrastructure for local development. Run these services once
and reuse them from any project (for example `ai-agent-service` or
`mcp-server`), instead of duplicating them in every `docker-compose.yml`.

## Services

Services are grouped in [Compose profiles](https://docs.docker.com/compose/how-tos/profiles/),
so you start only what you need.

| Service | Profile | Purpose | Host URL | In-network URL |
|---|---|---|---|---|
| `ollama` | `llm`, `gateway` | Local LLM server | http://localhost:11434 | http://ollama:11434 |
| `ollama-pull` | `llm`, `gateway` | One-shot job that pulls the configured models, then exits | n/a | n/a |
| `litellm` | `gateway` | OpenAI-compatible gateway in front of Ollama | http://localhost:4000 | http://litellm:4000 |
| `chromadb` | `vector` | Vector database | http://localhost:8001 | http://chromadb:8000 |
| `otel-collector` | `observability` | OTLP entry point for traces; fans out to Jaeger, Phoenix and, optionally, Azure Monitor | `localhost:4317` (gRPC), `localhost:4318` (HTTP) | `otel-collector:4317` / `:4318` |
| `jaeger` | `observability` | Trace storage and UI (in memory) | UI: http://localhost:16686 | n/a |
| `phoenix` | `observability` | LLM trace and eval UI (Arize Phoenix, SQLite volume) | UI: http://localhost:6006 | http://phoenix:6006 (REST API) |
| `postgres` | `db` | PostgreSQL 18 with pgvector | `localhost:5432` | `postgres:5432` |
| `redis` | `cache` | Cache / queues | `localhost:6379` | `redis:6379` |

All host ports bind to `127.0.0.1`: they are not reachable from the LAN.

The exact variables each consumer should use are in
[docs/service-contract.md](docs/service-contract.md).

## Quick start

```bash
cp .env.example .env            # default profiles: llm,vector,observability
docker compose up -d --wait     # starts and waits until healthchecks pass
docker logs -f ollama-pull      # follow the model downloads
```

Without `COMPOSE_PROFILES` (in `.env` or the shell), `docker compose up`
starts nothing. To start a profile ad hoc:
`docker compose --profile db up -d`.

### Azure Monitor and Microsoft Foundry (optional)

The collector can also send traces to Azure Monitor Application Insights,
where Microsoft Foundry shows them (project > Observability > Traces). Jaeger
and Phoenix keep receiving everything; Azure gets its own pipeline, queue and
retries ([config/otel-collector/azure-monitor.yaml](config/otel-collector/azure-monitor.yaml)).

1. Get the connection string of the Application Insights resource (an
   ingestion key: it only writes, but keep it out of git):

   ```bash
   az monitor app-insights component show -a <name> -g <resource-group> \
     --query connectionString -o tsv
   ```

2. Put it in `.env` as `APPLICATIONINSIGHTS_CONNECTION_STRING=...`.
3. Start with the override: `make up-azure`, or
   `docker compose -f docker-compose.yml -f docker-compose.azure.yml up -d --wait`.
   To make it the default, set `COMPOSE_FILE` in `.env`:
   `docker-compose.yml:docker-compose.azure.yml` on Linux, macOS and WSL, or
   `docker-compose.yml;docker-compose.azure.yml` on Windows (Compose uses the
   operating system's path separator).

Consumers change nothing: they keep sending to `otel-collector`. Spans reach
Application Insights after a few minutes. Traces leave your machine in this
mode, so check what your services put in span attributes (prompts, documents)
before turning it on; Application Insights also bills by ingested volume.

### GPU (NVIDIA)

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --wait
```

Needs the NVIDIA Container Toolkit (on Windows, Docker Desktop with WSL2).
Without it, Ollama runs on the CPU.

## Configuration

Edit `.env` (see [.env.example](.env.example) for all variables):

| Variable | Default | Description |
|---|---|---|
| `COMPOSE_PROFILES` | `llm,vector,observability` | Profiles to start |
| `OLLAMA_MODELS_TO_PULL` | `qwen3:8b nomic-embed-text` | Space-separated list of models pulled on startup |
| `OLLAMA_NUM_PARALLEL` | `2` | Concurrent requests per loaded model |
| `OLLAMA_MAX_LOADED_MODELS` | `2` | Models kept in memory at once |
| `OLLAMA_KEEP_ALIVE` | `30m` | How long an idle model stays loaded |
| `CHROMA_HOST_PORT` | `8001` | Host port mapped to Chroma's port 8000 |
| `LITELLM_HOST_PORT` / `LITELLM_MASTER_KEY` | `4000` / `sk-local-dev` | Gateway port and API key |
| `POSTGRES_*` | `5432`, `postgres`/`postgres`, `app` | Port, credentials and database |
| `REDIS_HOST_PORT` | `6379` | Host port for Redis |
| `PHOENIX_HOST_PORT` | `6006` | Host port for the Phoenix UI and REST API |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | unset | Azure Monitor target; used only with `docker-compose.azure.yml` |
| `COMPOSE_FILE` | unset | `docker-compose.yml:docker-compose.azure.yml` (`;` instead of `:` on Windows) to always load the Azure override |

Image versions are pinned in `docker-compose.yml`; Dependabot opens a PR
when a new version is released. Data lives in named volumes and survives
`down`; only `make clean` (`down -v`) deletes it. Jaeger keeps traces in
memory, so they are lost when it restarts; Phoenix keeps them in the
`phoenix_data` volume.

Phoenix is licensed under the Elastic License 2.0 (source-available, not OSI
open source): fine for local and internal use, but it may not be offered to
third parties as a managed service.

## Using it from another project

All services join the external network `docker-env-net`:

```yaml
services:
  app:
    env_file: docker-env.env    # copied from consumer.env.example
    networks:
      - shared

networks:
  shared:
    name: docker-env-net
    external: true
```

Inside the network, use service names (`ollama`, `otel-collector`), not
`localhost`. Start `docker-env` **before** your projects, otherwise the
external network does not exist yet. Step-by-step guide:
[docs/adding-a-project.md](docs/adding-a-project.md).

## Commands

`make` is optional. The table shows the plain Docker command for each target
(useful on Windows, where `make` is usually not installed).

| Make | Docker Compose | Description |
|---|---|---|
| `make up` | `docker compose up -d --wait` | Start the selected profiles |
| `make up-gpu` | `docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --wait` | Start with GPU |
| `make up-azure` | `docker compose -f docker-compose.yml -f docker-compose.azure.yml up -d --wait` | Start, also exporting traces to Azure Monitor |
| `make down` | `docker compose --profile "*" down` | Stop everything (volumes kept) |
| `make clean` | `docker compose --profile "*" down -v` | Stop and **delete** volumes |
| `make logs` | `docker compose logs -f` | Follow the logs |
| `make status` | `docker compose --profile "*" ps` | Container status and health |
| `make models` | `docker exec ollama ollama list` | List installed models |
| `make pull` | `docker compose run --rm ollama-pull` | Pull the configured models now |
| `make config` | `docker compose --profile "*" config --quiet` | Validate the compose file |

## Versioning

This repository is a shared contract. Changes are recorded in
[CHANGELOG.md](CHANGELOG.md) and released as git tags (`vMAJOR.MINOR.PATCH`).
Renaming a service, changing an in-network port or removing a variable is a
breaking change (major version).

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md).

## License

MIT
