# Adding a project to docker-env

1. Make sure `docker-env` is running: `docker compose up -d`.
2. In the project's compose file, declare the external network
   `docker-env-net` and attach the service to it.
3. Reference the shared services by name: `http://ollama:11434`,
   `http://jaeger:4318/v1/traces`.
4. Make sure the models your project needs are listed in
   `OLLAMA_MODELS_TO_PULL`.