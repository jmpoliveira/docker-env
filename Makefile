# Load .env so targets see the same values as docker compose.
-include .env
COMPOSE_PROFILES ?= llm,vector,observability
CHROMA_HOST_PORT ?= 8001
export

COMPOSE := docker compose
COMPOSE_GPU := $(COMPOSE) -f docker-compose.yml -f docker-compose.gpu.yml
COMPOSE_AZURE := $(COMPOSE) -f docker-compose.yml -f docker-compose.azure.yml

.DEFAULT_GOAL := help
.PHONY: help up up-gpu up-azure down clean logs status models pull config chroma-health

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

up: ## Start the services in COMPOSE_PROFILES and wait until healthy
	$(COMPOSE) up -d --wait

up-gpu: ## Same as up, with NVIDIA GPU for Ollama
	$(COMPOSE_GPU) up -d --wait

up-azure: ## Same as up, and also export traces to Azure Monitor (needs APPLICATIONINSIGHTS_CONNECTION_STRING)
	$(COMPOSE_AZURE) up -d --wait

down: ## Stop all services (volumes are kept)
	$(COMPOSE) --profile "*" down

clean: ## Stop all services and DELETE volumes (models, vectors, data)
	@echo "This deletes all docker-env volumes. Press Ctrl+C within 5s to abort."; sleep 5
	$(COMPOSE) --profile "*" down -v

logs: ## Follow the logs
	$(COMPOSE) logs -f

status: ## Show container status and health
	$(COMPOSE) --profile "*" ps

models: ## List the installed Ollama models
	docker exec ollama ollama list

pull: ## Pull the models in OLLAMA_MODELS_TO_PULL now
	$(COMPOSE) run --rm ollama-pull

config: ## Validate the compose file with every profile enabled
	$(COMPOSE) --profile "*" config --quiet

chroma-health: ## Call ChromaDB's heartbeat from the host
	curl -fsS http://localhost:$(CHROMA_HOST_PORT)/api/v2/heartbeat
