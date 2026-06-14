## ADDED Requirements

### Requirement: Startup validation
The system SHALL validate that the full stack starts successfully from a clean external-volume state.

#### Scenario: clean startup succeeds
- **WHEN** validation runs after creating empty external volumes
- **THEN** `postgres`, `vector-stack`, and `aspire-dashboard` become healthy or running

### Requirement: MCP connectivity validation
The system SHALL validate that each MCP server can be invoked through `docker exec -i vector-stack mcp-*`.

#### Scenario: qdrant MCP responds
- **WHEN** `docker exec -i vector-stack mcp-qdrant` is invoked with an MCP initialize request
- **THEN** it responds with MCP initialization data

#### Scenario: better-qdrant MCP responds
- **WHEN** `docker exec -i vector-stack mcp-better-qdrant` is invoked with an MCP initialize request
- **THEN** it responds with MCP initialization data

#### Scenario: Aperio MCP responds
- **WHEN** `docker exec -i vector-stack mcp-aperio` is invoked with an MCP initialize request
- **THEN** it responds with MCP initialization data

### Requirement: Code indexing validation
The system SHALL validate code indexing on a real project directory.

#### Scenario: code indexing stores chunks
- **WHEN** `index_codebase` is run against a project with source files
- **THEN** Qdrant contains indexed chunks with file path metadata

### Requirement: Semantic search validation
The system SHALL validate semantic search after indexing.

#### Scenario: semantic query returns results
- **WHEN** `search_code` is run with a natural language query
- **THEN** relevant code chunks are returned with scores

### Requirement: Persistence validation
The system SHALL validate that Qdrant and PostgreSQL data survive `docker compose down` and restart.

#### Scenario: indexed data survives restart
- **WHEN** data is indexed, the stack is stopped with `docker compose down`, and the stack starts again
- **THEN** the indexed collections and stored memories remain available

### Requirement: Reset validation
The system SHALL validate soft reset, hard reset, and memory reset workflows.

#### Scenario: reset removes intended state
- **WHEN** a reset command is run
- **THEN** only the intended state is removed and the stack can start again

### Requirement: Multi-runtime connectivity validation
The system SHALL document validation steps for Docker Engine, Docker Desktop, Rancher Desktop/Lima, and Podman where applicable.

#### Scenario: host Ollama connectivity is verified
- **WHEN** validation runs on a supported runtime
- **THEN** the documented connectivity check confirms Ollama is reachable from `vector-stack`

### Requirement: mxbai validation path
The system SHALL document validation steps for switching to `mxbai-embed-large` without reusing nomic indexes.

#### Scenario: mxbai collection is validated
- **WHEN** mxbai evaluation is performed
- **THEN** a 1024-dimensional collection is created, indexed, searched, and compared separately from nomic results
