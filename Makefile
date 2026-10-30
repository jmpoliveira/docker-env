.PHONY: up down logs models status chroma-health

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

models:
	docker exec ollama ollama list

status:
	docker compose ps

chroma-health:
	curl -fsS http://localhost:$${CHROMA_HOST_PORT:-8001}/api/v2/heartbeat