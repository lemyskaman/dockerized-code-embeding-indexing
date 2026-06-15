## 1. Compose Overlay and Networking

- [ ] 1.1 Add `docker-compose.override.yaml` with `postgres`, `vector-stack`, and `aspire-dashboard` services
- [ ] 1.2 Define shared `app-network` bridge network for all AI services
- [ ] 1.3 Declare external `pgdata`, `qdrant-storage`, and `aperio-cache` volumes
- [ ] 1.4 Configure `vector-stack` host Ollama connectivity with `host.docker.internal` and `OLLAMA_HOST_IP` override
- [ ] 1.5 Configure read-only workspace mount at `/workspace` using configurable `WORKSPACE_PATH`
- [ ] 1.6 Map host-accessible services to non-standard ports: PostgreSQL `15432:5432`, Qdrant REST `16333:6333`, Qdrant gRPC `16334:6334`, Aspire HTTP `18888:18888`, and Aspire OTLP `18889:18889`

## 2. Vector Stack Image

- [ ] 2.1 Create `dev-docker-env/dockerfiles/Dockerfile.vector-stack` from `qdrant/qdrant:v1.16.3`
- [ ] 2.2 Install Node.js 20 and build tools required by native MCP dependencies
- [ ] 2.3 Install upstream `@mhalder/qdrant-mcp-server` v3.3.5 or newer
- [ ] 2.4 Install `better-qdrant-mcp-server` as a local dependency, not via runtime `npx`
- [ ] 2.5 Install Aperio v0.50.1 or newer
- [ ] 2.6 Patch Aperio `logger.warning()` usage to `logger.warn()` during build if needed
- [ ] 2.7 Create `mcp-qdrant`, `mcp-better-qdrant`, and `mcp-aperio` wrapper scripts with isolated environment variables
- [ ] 2.8 Add custom entrypoint that starts Qdrant, waits for health, and keeps the container alive

## 3. PostgreSQL and pgvector

- [ ] 3.1 Create `dev-docker-env/dockerfiles/Dockerfile.postgres-pgvector` from `postgres:18-alpine`
- [ ] 3.2 Install pgvector v0.8.1 or newer compatible with PostgreSQL 18
- [ ] 3.3 Add `dev-docker-env/config/postgres-init/01-aperio.sql`
- [ ] 3.4 Create Aperio role, database, and enable `vector` and `pgcrypto` extensions
- [ ] 3.5 Add PostgreSQL health check using `pg_isready`

## 4. Observability

- [ ] 4.1 Add Aspire Dashboard service to `docker-compose.override.yaml`
- [ ] 4.2 Map host port `18888` to dashboard HTTP and `18889` to OTLP gRPC
- [ ] 4.3 Configure unsecured local dashboard access
- [ ] 4.4 Document OTLP environment variables for services that send telemetry

## 5. Ollama and Embedding Models

- [ ] 5.1 Document host Ollama prerequisite and required `ollama pull` commands
- [ ] 5.2 Investigate whether `mxbai-embed-large` can be made to work reliably in this stack
- [ ] 5.3 Use `nomic-embed-text:v1.5` as the fallback default when mxbai is not reliable
- [ ] 5.4 Set default `qwen2.5:3b` chat model for Aperio
- [ ] 5.5 Document optional `mxbai-embed-large` path with 1024-dimensional collections and stricter chunking
- [ ] 5.6 Add Ollama connectivity verification command for `vector-stack`

## 6. MCP Client Templates

- [ ] 6.1 Add `dev-docker-env/config/mcp/mcp-config.vscode.json`
- [ ] 6.2 Add `dev-docker-env/config/mcp/mcp-config.claude.json`
- [ ] 6.3 Add `dev-docker-env/config/mcp/mcp-config.cursor.json`
- [ ] 6.4 Use stdio `docker exec -i vector-stack mcp-*` transport in every template
- [ ] 6.5 Expose both `mcp-qdrant` and `mcp-better-qdrant` by default, with `mcp-aperio` available for memory/wiki
- [ ] 6.6 Document where each template should be copied for VS Code, Claude Code/Claude Desktop, and Cursor

## 7. Tooling CLI and Scripts

- [ ] 7.1 Create `dev-docker-env/scripts/start.sh` for volume creation and stack startup
- [ ] 7.2 Create `dev-docker-env/scripts/ai-stack.sh` with `status`, `reset`, and `reindex` commands
- [ ] 7.3 Create `dev-docker-env/scripts/vector-stack-entrypoint.sh`
- [ ] 7.4 Add `dev-docker-env/config/env/.env.example`
- [ ] 7.5 Add workspace path resolution from project `.nsv`, local `.env`, repository root, or `${HOME}/projects`
- [ ] 7.6 Mark shell scripts executable

## 8. Documentation

- [ ] 8.1 Create root `README.md` with prerequisites, quick start, configuration, and troubleshooting
- [ ] 8.2 Create `dev-docker-env/docs/ARCHITECTURE.md` explaining the implementation design
- [ ] 8.3 Document reset and hard reset behaviour for external volumes
- [ ] 8.4 Document Docker runtime edge cases for host Ollama connectivity
- [ ] 8.5 Document project `.nsv` workspace configuration and local `.env` override behaviour
- [ ] 8.6 Document non-standard host port mappings and when to access services from the host
- [ ] 8.7 Document mxbai vs nomic evaluation guidance and reindex requirements

## 9. Validation

- [ ] 9.1 Validate clean startup with empty external volumes
- [ ] 9.2 Validate MCP initialization for qdrant, better-qdrant, and aperio
- [ ] 9.3 Validate code indexing on a real project directory
- [ ] 9.4 Validate semantic search returns chunks with file paths and scores
- [ ] 9.5 Validate Qdrant and PostgreSQL persistence across `docker compose down` and restart
- [ ] 9.6 Validate reset workflows remove only the intended state
- [ ] 9.7 Validate optional mxbai path with a separate 1024-dimensional collection if mxbai is feasible; otherwise validate the proven nomic path from the example project notes
