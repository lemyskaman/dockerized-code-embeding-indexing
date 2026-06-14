## Context

The research report defines a reusable AI development tooling stack for local software projects. The stack must provide codebase semantic search, persistent AI memory, vector storage, and MCP server orchestration while staying portable across projects. The prior implementation proved the architecture in `container-onramp-supplemental-api`, including Qdrant, pgvector, Aperio, Ollama, and MCP clients. It also identified critical issues that must be fixed before generalisation: Qdrant JS client compatibility failures, silent Ollama embedding batch failures, `npx` cache instability, Aperio logging incompatibility, host Ollama networking, and external volume persistence.

The implementation is constrained by the research decisions: the toolkit must live under `dev-docker-env/`, activate through `docker-compose.override.yaml`, run Ollama on the host, invoke MCP servers on demand through `docker exec -i`, store persistent data in external named volumes, and isolate MCP environment variables with wrapper scripts.

## Goals / Non-Goals

**Goals:**

- Provide a project-agnostic Docker Compose overlay that adds AI tooling without modifying the host project's base compose file.
- Run Qdrant, qdrant-mcp-server, better-qdrant-mcp-server, and aperio inside a single `vector-stack` container.
- Invoke MCP servers on demand through `docker exec -i vector-stack mcp-*` so idle resource usage stays near zero.
- Persist Qdrant, PostgreSQL, and Aperio cache data in external Docker volumes.
- Use host-installed Ollama for embeddings and local chat models.
- Pin upstream `qdrant-mcp-server` v3.3.5+ so PR #60 fixes are inherited without carrying a fork.
- Keep `nomic-embed-text:v1.5` as the default embedding model and document an optional `mxbai-embed-large` evaluation path.
- Provide reusable CLI scripts, MCP client templates, documentation, and validation checks.

**Non-Goals:**

- Do not modify the host project's `docker-compose.yaml`.
- Do not run Ollama inside Docker for the first implementation.
- Do not implement GPU acceleration in the first implementation.
- Do not migrate existing indexes automatically between embedding models.
- Do not implement production multi-user access control, authentication, or remote hosting.
- Do not replace the research report; implementation artifacts should operationalise it.

## Decisions

### Decision: Use Docker Compose override as the activation boundary

The AI stack is added through `docker-compose.override.yaml` and files under `dev-docker-env/`. This keeps the host project's base compose file unchanged and makes the toolkit removable by deleting the override and toolkit directory.

Alternatives considered:

- Modifying the host project's `docker-compose.yaml` directly would be simpler but breaks portability.
- A standalone compose file would avoid merge behaviour but makes lifecycle management less discoverable.

### Decision: Use one `vector-stack` container for Qdrant and MCP servers

Qdrant runs as the persistent process in the container, while MCP servers are invoked on demand with `docker exec -i vector-stack mcp-*`. This gives shared loopback access to Qdrant, one container to manage, and no idle MCP server overhead.

Alternatives considered:

- Separate containers per MCP server increase network configuration and management complexity.
- Persistent MCP server processes waste CPU/RAM and complicate lifecycle control.
- Host-installed MCP servers defeat dockerisation and require Node.js on the host.

### Decision: Use upstream `qdrant-mcp-server` v3.3.5+

PR #60 was merged upstream and released as v3.3.5. It adds `checkCompatibility: false` for self-hosted Qdrant versions and 3800-character Ollama input truncation to prevent silent batch drops. The implementation must pin v3.3.5+ instead of carrying the earlier fork.

Alternatives considered:

- Continuing to use the fork would add maintenance burden.
- Using unpinned latest could introduce unrelated breaking changes.

### Decision: Keep Ollama on the host

Embedding and chat models are too large to bake into the container image, and a host Ollama instance can serve multiple projects. Containers reach the host through `host.docker.internal`.

Alternatives considered:

- Running Ollama in Docker simplifies container self-containment but increases image/runtime complexity and GPU passthrough burden.
- Using a remote embedding provider would reduce local resource usage but violates the local-first goal.

### Decision: Use `nomic-embed-text:v1.5` as default

`nomic-embed-text:v1.5` is small, fast, supported by the MCP servers, has an 8K context window, and was validated with the fixed qdrant-mcp-server path. It remains the default until a side-by-side benchmark proves `mxbai-embed-large` improves retrieval enough to justify larger size, slower inference, 1024-dimensional vectors, and 512-token context.

Alternatives considered:

- `mxbai-embed-large` has higher reported MTEB English quality but requires stricter chunking and separate Qdrant collections.
- `nomic-embed-code` is stronger for code but too large for many developer machines.
- `qwen3-embedding` is future-facing but not the first implementation choice.

### Decision: Use PostgreSQL + pgvector for Aperio memory

Aperio needs relational tables for memories and wiki articles plus vector search. PostgreSQL 18 with pgvector v0.8.1 satisfies both needs and gives ACID consistency for memory data.

Alternatives considered:

- LanceDB is useful as Aperio's zero-config fallback but lacks relational ACID semantics.
- Qdrant is excellent for code/document vectors but is not the primary store for Aperio's structured memory tables.

### Decision: Use Aspire Dashboard for observability

Aspire Dashboard receives standard OTLP and works across languages. It provides a local, low-configuration observability endpoint for traces, logs, and metrics.

Alternatives considered:

- Jaeger/Tempo/Prometheus would require more services and configuration.
- No observability would make MCP and stack failures harder to diagnose.

## Risks / Trade-offs

- [Qdrant version compatibility] → Pin `qdrant-mcp-server` v3.3.5+ and verify startup against Qdrant v1.16.3.
- [Ollama chunk overflow] → Keep `CODE_CHUNK_SIZE=1500`, rely on qdrant-mcp-server's 3800-character truncation, and use stricter chunk sizes for mxbai evaluation.
- [Host Ollama connectivity] → Use `host.docker.internal` with an `OLLAMA_HOST_IP` override for Rancher Desktop, Lima, and Podman edge cases.
- [External volume loss] → Create volumes before first run or through `start.sh`; document reset and hard-reset commands.
- [Aperio logging crash] → Patch `logger.warning()` to `logger.warn()` during Docker build until upstream resolves it.
- [mxbai model switch] → Require a separate collection and reindex because vector dimensions and values are incompatible with nomic indexes.
- [Tree-sitter native compilation] → Pin Node.js 20 and document native build tool requirements.
- [MCP client config drift] → Provide templates for VS Code, Claude Code/Claude Desktop, and Cursor and document how to copy them.

## Migration Plan

1. Create the toolkit files under `dev-docker-env/`.
2. Add root `docker-compose.override.yaml` and `README.md`.
3. Create external volumes with `docker volume create pgdata`, `docker volume create qdrant-storage`, and `docker volume create aperio-cache`, or use `start.sh`.
4. Pull required Ollama models: `ollama pull nomic-embed-text:v1.5` and `ollama pull qwen2.5:3b`; optionally pull `mxbai-embed-large`.
5. Start the stack with `./dev-docker-env/scripts/start.sh` or `docker compose up -d`.
6. Copy the appropriate MCP client template into the IDE/client configuration.
7. Run validation checks for service health, MCP connectivity, code indexing, search, memory persistence, and reset/reindex workflows.
8. Roll back by running `docker compose down`, removing the override file, and restoring prior MCP client configuration.

## Open Questions

- Which host projects directory should be mounted by default: `${HOME}/projects`, the repository root, or a configurable `WORKSPACE_PATH`?
- Should the first implementation expose both `qdrant-mcp-server` and `better-qdrant-mcp-server` to clients by default, or only the primary code indexing server?
- Should validation include an automated benchmark comparing `nomic-embed-text:v1.5` and `mxbai-embed-large`, or only document the benchmark procedure?
