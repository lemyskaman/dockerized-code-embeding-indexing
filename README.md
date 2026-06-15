# Dockerized AI Dev Tooling Stack

This repository contains a reusable Docker Compose overlay for local AI development tooling. It adds Qdrant, qdrant-mcp-server, better-qdrant-mcp-server, Aperio, PostgreSQL + pgvector, Ollama integration, and Aspire Dashboard without modifying a host project's base `docker-compose.yaml`.

## Prerequisites

- Docker Engine or Docker Desktop with Compose v2.24+
- Ollama installed on the host
- Python 3 and `jq` on the host for the helper scripts
- Optional: `ollama` models available locally

Pull the default models:

```bash
ollama pull nomic-embed-text:v1.5
ollama pull qwen2.5:3b
```

Optional model investigation:

```bash
ollama pull mxbai-embed-large
```

Use `mxbai-embed-large` only after validating that it works reliably in this stack. If it does not, keep `nomic-embed-text:v1.5` as the default. mxbai requires a separate 1024-dimensional Qdrant collection and stricter chunking.

## Quick start

Create the required external volumes:

```bash
docker volume create pgdata
docker volume create qdrant-storage
docker volume create aperio-cache
```

Start the stack and index the mounted workspace:

```bash
./dev-docker-env/scripts/start.sh
```

Start the stack but index a narrower path, useful for large monorepos:

```bash
./dev-docker-env/scripts/start.sh --index-path=/workspace/apps/api/src
```

Skip automatic indexing if desired:

```bash
./dev-docker-env/scripts/start.sh --skip-index
```

## Workspace configuration

The stack mounts a host directory read-only into the container at `/workspace`.

Resolution order:

1. `WORKSPACE_PATH` in local `.env`
2. `workspace_path` in project `.nsv`
3. `REPOSITORY_ROOT` in local `.env`
4. `repository_root` in project `.nsv`
5. Repository root `src` directory, if it exists
6. `${HOME}/projects`
7. Repository root

Example `.nsv`:

```text
workspace_path=/home/lemys/projects/my-project/src
repository_root=/home/lemys/projects/my-project
```

Local `.env` remains available for developer-specific overrides such as `OLLAMA_HOST_IP`.

## Host ports

All host-accessible services use non-standard ports:

| Service | Host URL | Container port |
| :--- | :--- | :--- |
| Qdrant REST | http://localhost:26333 | 6333 |
| Qdrant gRPC | localhost:26334 | 6334 |
| PostgreSQL | localhost:25432 | 5432 |
| Aspire Dashboard | http://localhost:28888 | 18888 |
| Aspire OTLP gRPC | localhost:28889 | 18889 |

## Ollama connectivity

The containers first try `http://host.docker.internal:11434`. If that fails, `start.sh` auto-detects the host LAN IP and recreates `vector-stack` with `OLLAMA_HOST_IP`.

For Rancher Desktop, Lima, Podman, or other non-standard Docker runtimes, set `OLLAMA_HOST_IP` in `.env` to the host LAN IP and recreate the container:

```bash
docker compose -f docker-compose.override.yaml up -d --force-recreate vector-stack
```

## MCP client templates

Templates live in `dev-docker-env/config/mcp/`.

- VS Code: copy `mcp-config.vscode.json` to `.vscode/mcp.json` or your user MCP config.
- Claude Code/Claude Desktop: copy `mcp-config.claude.json` to the client MCP config.
- Cursor: copy `mcp-config.cursor.json` to `.cursor/mcp.json`.

The first implementation exposes all three MCP servers:

- `qdrant`
- `better-qdrant`
- `aperio`

## CLI

Status:

```bash
./dev-docker-env/scripts/ai-stack.sh status
```

Soft reset Qdrant collections:

```bash
./dev-docker-env/scripts/ai-stack.sh reset
```

Hard reset Qdrant and Aperio cache volumes:

```bash
./dev-docker-env/scripts/ai-stack.sh reset --hard --yes
```

Reset Aperio memory and wiki tables:

```bash
./dev-docker-env/scripts/ai-stack.sh reset --memory --yes
```

Reindex a workspace path:

```bash
./dev-docker-env/scripts/ai-stack.sh reindex /workspace
```

## Observability

Aspire Dashboard is available at http://localhost:28888.

Services can send OpenTelemetry to:

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://aspire-dashboard:18889
OTEL_SERVICE_NAME=<service-name>
OTEL_LOGS_EXPORTER=otlp
```

## Reset and persistence

Data is stored in external Docker volumes:

- `pgdata`
- `qdrant-storage`
- `aperio-cache`

`docker compose down` does not delete external volumes. Use `docker volume rm <name>` only when you intentionally want to delete data.

## Troubleshooting

### Qdrant is not reachable

Check the container:

```bash
docker compose ps
docker compose logs vector-stack
curl http://localhost:26333/healthz
```

### Ollama is not reachable from the container

Run:

```bash
docker exec vector-stack curl -s http://host.docker.internal:11434/api/tags
```

If this fails, `start.sh` can auto-detect the host LAN IP. You can also set `OLLAMA_HOST_IP` in `.env`, for example:

```text
OLLAMA_HOST_IP=192.168.1.6
```

### MCP server does not appear in the client

Reload the AI client after copying the MCP config. Verify the server directly:

```bash
docker exec -i vector-stack mcp-qdrant
docker exec -i vector-stack mcp-better-qdrant
docker exec -i vector-stack mcp-aperio
```
