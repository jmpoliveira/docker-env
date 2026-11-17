# Troubleshooting

## `docker compose up` says "no service selected"

`COMPOSE_PROFILES` is not set. Add it to `.env` (see `.env.example`) or pass
`--profile <name>`.

## Port already in use

Another process uses one of the host ports (11434, 4000, 8001, 4317, 4318,
16686, 5432, 6379). Change the matching `*_HOST_PORT` variable in `.env`, or
stop the other process. On Windows, a native Ollama install also listens on
11434: quit it from the tray icon.

## `network docker-env-net not found` in another project

Start `docker-env` first: `docker compose up -d`. The network is created by
this project.

## `ollama-pull` exited with code 1

Wrong model name or no disk space. Check `docker logs ollama-pull`, fix
`OLLAMA_MODELS_TO_PULL`, then run `make pull`.

## A container stays `unhealthy` / `up --wait` times out

Check `docker compose --profile "*" ps` and `docker logs <container>`. The
first start of `litellm` is slower; its healthcheck allows 30 s.

## Traces do not show in Jaeger

- The app must send to `otel-collector:4318` (HTTP) or `:4317` (gRPC) from
  inside the network, or `localhost:4318` from the host.
- Set `OTEL_SERVICE_NAME`, then look for that name in the Jaeger UI.
- `docker logs otel-collector` shows export errors.
- Jaeger stores traces in memory: they disappear when it restarts.

## Ollama is slow / runs on the CPU

Start with the GPU override (`make up-gpu`) and check `docker logs ollama`
for the detected GPU. If several services use different models, raise
`OLLAMA_MAX_LOADED_MODELS` (needs more RAM/VRAM).

## Postgres `init.sql` did not run

Init scripts run only when the data volume is empty. To re-run, delete the
volume: `docker compose --profile db down` and `docker volume rm docker-env_postgres_data`
(this deletes the data).
