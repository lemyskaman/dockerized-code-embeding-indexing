## Why

Developers need a reusable, project-agnostic AI development stack that provides codebase semantic search, persistent AI memory, vector storage, and MCP server orchestration without modifying each host project's base Docker Compose configuration. The existing research report proves the stack with a prior implementation and identifies the production issues that must be addressed before generalising it into a portable toolkit.

## What Changes

- Adds a dockerized AI tooling overlay that activates through `docker-compose.override.yaml` and keeps the host project's base compose file unchanged.
- Adds a `vector-stack` container that runs Qdrant as the persistent service and invokes MCP servers on demand through `docker exec -i`.
- Adds PostgreSQL + pgvector storage for Aperio memory and wiki data, plus optional LanceDB fallback behaviour through Aperio's own configuration.
- Adds Aspire Dashboard as the observability endpoint for OpenTelemetry traces, logs, and metrics.
- Adds wrapper scripts that isolate environment variables for each MCP server.
- Adds management automation for volume creation, stack startup, health checks, reset/reindex workflows, and MCP client configuration templates.
- Pins the stack to `qdrant-mcp-server` v3.3.5+ so the Qdrant compatibility and Ollama chunking fixes from PR #60 are inherited upstream.
- Keeps `nomic-embed-text:v1.5` as the default Ollama embedding model while documenting `mxbai-embed-large` as an optional higher-quality alternative that requires separate collections and stricter chunking.

## Capabilities

### New Capabilities

- `docker-compose-overlay`: Project-agnostic Docker Compose override services, networks, external volumes, and host Ollama connectivity.
- `vector-stack`: Qdrant-backed container image containing Qdrant, qdrant-mcp-server, better-qdrant-mcp-server, aperio, wrapper scripts, and custom entrypoint.
- `qdrant-code-indexing`: AST-aware code indexing, semantic search, incremental reindexing, git history indexing, and collection management through qdrant-mcp-server.
- `document-rag`: General document ingestion and semantic search through better-qdrant-mcp-server.
- `aperio-memory`: Persistent AI memory, wiki articles, file scanning, shell access, and memory/wiki search through Aperio.
- `postgres-pgvector`: PostgreSQL 18 + pgvector database for Aperio memory/wiki storage and vector search.
- `observability`: Aspire Dashboard integration for OpenTelemetry collection and visualization.
- `ollama-embeddings`: Host Ollama integration with `nomic-embed-text:v1.5` as default and optional `mxbai-embed-large` evaluation path.
- `mcp-client-templates`: MCP client configuration templates for VS Code, Claude Code/Claude Desktop, and Cursor.
- `tooling-cli`: Local scripts for stack lifecycle, volume setup, health checks, reset/reindex workflows, and one-command startup.
- `validation`: End-to-end validation checks for startup, MCP connectivity, indexing, persistence, and multi-project use.

### Modified Capabilities

<!-- No existing specs are present in this repository yet. -->

## Impact

- Adds files under `dev-docker-env/`, root-level `docker-compose.override.yaml`, and root-level `README.md`.
- Adds OpenTelemetry-compatible observability through Aspire Dashboard.
- Adds host-side Ollama as a required dependency and may require `OLLAMA_HOST_IP` overrides on Rancher Desktop/Lima/Podman.
- Adds external Docker volumes that must be created before first run or by the startup script.
- Adds MCP server dependencies installed inside Docker instead of relying on host `npx` caches.
- Requires project source directories to be mounted read-only under `/workspace` for indexing and Aperio file tools.
