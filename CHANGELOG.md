# Changelog

All notable changes to the shared contract are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions
follow [Semantic Versioning](https://semver.org/). See
[docs/service-contract.md](docs/service-contract.md) for what counts as a
breaking change.

## [Unreleased]

### Added
- `phoenix` (Arize Phoenix 21.0.0) in the `observability` profile: LLM trace
  and eval UI on port 6006, data in the `phoenix_data` volume.
- The collector now exports traces to both Jaeger and Phoenix.
- Compose profiles: `llm`, `gateway`, `vector`, `observability`, `db`, `cache`.
- `otel-collector` as the OTLP entry point (host ports 4317/4318 now go to it).
- `litellm` OpenAI-compatible gateway, `postgres` (pgvector) and `redis`.
- Healthchecks for every long-running service.
- GPU override file `docker-compose.gpu.yml`.
- Service contract, `consumer.env.example`, troubleshooting guide.
- Smoke test in CI and Dependabot for image tags and actions.

### Changed
- **Breaking:** `COMPOSE_PROFILES` must be set; without it nothing starts.
- **Breaking:** `ollama-init` renamed to `ollama-pull`.
- All host ports bind to `127.0.0.1` only.
- Default models: `qwen3:8b nomic-embed-text`.
- Images pinned: Ollama 0.40.15, Jaeger 2.23.0, Chroma 1.5.9.

### Removed
- `CHROMA_VERSION` variable (the tag is pinned in the compose file so
  Dependabot can update it).
