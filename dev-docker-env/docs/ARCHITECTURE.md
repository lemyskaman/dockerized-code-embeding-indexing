# AI Dev Tooling Stack Architecture

## Overview

The implementation is a project-agnostic Docker Compose overlay. It adds AI tooling through `docker-compose.override.yaml` and keeps all toolkit files under `dev-docker-env/`.

## Components

- `postgres`: PostgreSQL 18 + pgvector for Aperio memory and wiki data.
- `vector-stack`: Qdrant v1.16.3 plus qdrant-mcp-server, better-qdrant-mcp-server, and Aperio.
- `aspire-dashboard`: Local OpenTelemetry dashboard.
- Host Ollama: Embedding and chat model runtime accessed through `host.docker.internal`, with `start.sh` auto-fallback to `OLLAMA_HOST_IP` when needed.

## Container ports and host mappings

Container ports remain standard. Host ports are non-standard to avoid conflicts.

| Service | Host port | Container port |
| :--- | ---: | ---: |
| PostgreSQL | 25432 | 5432 |
| Qdrant REST | 26333 | 6333 |
| Qdrant gRPC | 26334 | 6334 |
| Aspire Dashboard HTTP | 28888 | 18888 |
| Aspire Dashboard OTLP gRPC | 28889 | 18889 |

## MCP execution model

MCP servers are not persistent daemons. They are invoked on demand:

```bash
docker exec -i vector-stack mcp-qdrant
docker exec -i vector-stack mcp-better-qdrant
docker exec -i vector-stack mcp-aperio
```

Wrapper scripts isolate environment variables so qdrant, better-qdrant, and Aperio can use different model and provider settings.

## Workspace resolution

The host workspace is mounted read-only at `/workspace`.

Resolution order:

1. `WORKSPACE_PATH` in local `.env`
2. `workspace_path` in project `.nsv`
3. `REPOSITORY_ROOT` in local `.env`
4. `repository_root` in project `.nsv`
5. Repository `src` directory, if present
6. `${HOME}/projects`
7. Repository root

This makes project-level `.nsv` configuration portable while preserving local `.env` overrides.

## Embedding model strategy

`nomic-embed-text:v1.5` is the default because it is small, fast, has an 8K context window, and was validated with qdrant-mcp-server v3.3.5+.

`mxbai-embed-large` is investigated as an optional higher-quality model. It must use a separate 1024-dimensional Qdrant collection and stricter chunking. If it cannot be made reliable, the stack uses the proven nomic path.

## Persistence

External Docker volumes store state:

- `pgdata`: PostgreSQL data
- `qdrant-storage`: Qdrant collections and vectors
- `aperio-cache`: Aperio cache and downloaded ONNX model data

`docker compose down` preserves these volumes.

## Observability

Aspire Dashboard receives OTLP at `http://aspire-dashboard:18889` and exposes the UI on host port `28888`.

Services should set:

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://aspire-dashboard:18889
OTEL_SERVICE_NAME=<service-name>
OTEL_LOGS_EXPORTER=otlp
```

## Scripts

- `start.sh`: loads local configuration, resolves workspace path, creates volumes, starts Compose, checks Ollama connectivity, and optionally indexes `INDEX_PATH` (default `/workspace`).
- `ai-stack.sh`: provides `status`, `reset`, and `reindex` commands.
- `vector-stack-entrypoint.sh`: starts Qdrant, waits for health, and keeps the container alive.
