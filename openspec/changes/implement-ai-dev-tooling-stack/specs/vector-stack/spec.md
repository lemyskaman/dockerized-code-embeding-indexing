## ADDED Requirements

### Requirement: Qdrant base image
The system SHALL build `vector-stack` from `qdrant/qdrant:v1.16.3` or a compatible Qdrant v1.16+ image.

#### Scenario: Qdrant process starts
- **WHEN** `vector-stack` starts
- **THEN** Qdrant listens on container port `6333` and gRPC port `6334`

### Requirement: Node.js runtime
The system SHALL install Node.js 20 inside `vector-stack` for MCP server execution.

#### Scenario: Node.js version is pinned
- **WHEN** `docker exec vector-stack node --version` is run
- **THEN** the reported major version is Node.js 20

### Requirement: qdrant-mcp-server version
The system SHALL install upstream `@mhalder/qdrant-mcp-server` v3.3.5 or newer.

#### Scenario: Upstream fixes are present
- **WHEN** the image is built
- **THEN** the installed qdrant-mcp-server version is v3.3.5 or newer and does not require the old fork

### Requirement: MCP wrapper scripts
The system SHALL create `/usr/local/bin/mcp-qdrant`, `/usr/local/bin/mcp-better-qdrant`, and `/usr/local/bin/mcp-aperio` wrapper scripts.

#### Scenario: Wrapper scripts are executable
- **WHEN** `docker exec vector-stack ls -l /usr/local/bin/mcp-*` is run
- **THEN** all three wrapper scripts exist and are executable

### Requirement: Environment isolation
Each MCP wrapper SHALL export only the environment variables required by that MCP server before executing the Node.js process.

#### Scenario: qdrant environment is isolated
- **WHEN** `mcp-qdrant` is executed
- **THEN** it receives `QDRANT_URL`, Ollama embedding variables, `EMBEDDING_MODEL`, and `CODE_CHUNK_SIZE` without conflicting with Aperio variables

#### Scenario: Aperio environment is isolated
- **WHEN** `mcp-aperio` is executed
- **THEN** it receives PostgreSQL, Ollama chat, and Aperio-specific variables without conflicting with qdrant-mcp-server variables

### Requirement: Custom entrypoint
The system SHALL start Qdrant in the background, wait until it is healthy, and keep the container alive.

#### Scenario: Qdrant health is waited on
- **WHEN** `vector-stack` starts
- **THEN** MCP wrapper scripts are available only after Qdrant accepts connections on `127.0.0.1:6333`

### Requirement: Aperio logger compatibility
The system SHALL patch Aperio's `logger.warning()` usage to `logger.warn()` during image build if the installed version still uses the old method name.

#### Scenario: Aperio starts under Node.js
- **WHEN** `mcp-aperio` is invoked
- **THEN** it does not crash because of `logger.warning is not a function`
