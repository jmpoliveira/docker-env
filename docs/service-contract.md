# Service contract

What consumer projects can rely on. Anything not listed here is an
implementation detail and may change without notice. Breaking any item below
requires a major version bump (see [CHANGELOG.md](../CHANGELOG.md)).

All addresses are for containers attached to the external network
`docker-env-net`. From the host, replace the hostname with `localhost` and use
the host port from the [README](../README.md).

| Capability | Profile | Hostname:port | Standard variables |
|---|---|---|---|
| LLM (native Ollama API) | `llm` | `ollama:11434` | `OLLAMA_BASE_URL=http://ollama:11434` |
| LLM (OpenAI-compatible) | `gateway` | `litellm:4000` | `OPENAI_BASE_URL=http://litellm:4000/v1`, `OPENAI_API_KEY=<LITELLM_MASTER_KEY>` |
| Vector store | `vector` | `chromadb:8000` | `CHROMA_HOST=chromadb`, `CHROMA_PORT=8000` |
| Tracing (OTLP) | `observability` | `otel-collector:4317` (gRPC), `otel-collector:4318` (HTTP) | `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318`, `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf` |
| LLM traces and evals (Phoenix REST API) | `observability` | `phoenix:6006` | none standard; configure the client base URL in the consumer's settings |
| Relational + vectors | `db` | `postgres:5432` | `DATABASE_URL=postgresql://<user>:<password>@postgres:5432/<db>` |
| Cache / queues | `cache` | `redis:6379` | `REDIS_URL=redis://redis:6379/0` |

Ready-to-copy file: [consumer.env.example](../consumer.env.example).

## Notes

- **OpenTelemetry:** use the standard `OTEL_*` variables so the SDK configures
  itself without code. With `OTEL_EXPORTER_OTLP_ENDPOINT`, the SDK appends
  `/v1/traces`; set `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` only if you need the
  full URL. Always set `OTEL_SERVICE_NAME` so services can be told apart in
  Jaeger.
- **Send telemetry to `otel-collector`, not `jaeger`.** The collector is the
  stable entry point; the backend behind it may change. `jaeger:4318` still
  works for now, but it is not part of the contract. The same applies to
  Phoenix: traces go through the collector; use `phoenix:6006` only for its
  REST API (for example the Phoenix client that uploads datasets and runs
  experiments). Authentication is disabled in this local environment.
- **Azure Monitor is opt-in and not part of the contract.** With
  `docker-compose.azure.yml`, the collector also exports traces to Application
  Insights. Consumers change nothing; they should still avoid putting secrets
  or personal data in span attributes, since traces may leave the machine.
- **Models:** LiteLLM exposes every Ollama model as `ollama/<name>`, for
  example `ollama/qwen3:8b`. The model must be listed in
  `OLLAMA_MODELS_TO_PULL` (or pulled with `make pull`). Embedding models
  must also be listed by name in `config/litellm/config.yaml`; only
  `ollama/nomic-embed-text` is configured today.
- **Postgres:** the `vector` extension is created in the default database on
  first start. Each project should use its own database or schema.
- **Redis:** use a key prefix (or a separate DB number) per project.
