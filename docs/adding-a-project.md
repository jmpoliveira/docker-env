# Adding a project to docker-env

1. Make sure `docker-env` is running with the profiles your project needs
   (set `COMPOSE_PROFILES` in this repo's `.env`), then run
   `docker compose up -d --wait`.
2. Copy [consumer.env.example](../consumer.env.example) into the project (for
   example as `docker-env.env`), set `OTEL_SERVICE_NAME` and remove the
   variables you do not use.
3. In the project's compose file, attach the service to the external network
   and load the env file:

   ```yaml
   services:
     app:
       env_file: docker-env.env
       networks:
         - shared

   networks:
     shared:
       name: docker-env-net
       external: true
   ```

4. Reference shared services by name, never `localhost`: `ollama:11434`,
   `litellm:4000`, `chromadb:8000`, `otel-collector:4318`, `postgres:5432`,
   `redis:6379`. Use the container ports, not the host ports.
5. Add the models your project needs to `OLLAMA_MODELS_TO_PULL` and run
   `make pull` (or `docker compose run --rm ollama-pull`).
6. With `db` or `cache`: create a dedicated database/schema or use a key
   prefix, so projects do not overwrite each other's data.

The full list of hostnames and variables is in
[service-contract.md](service-contract.md).
