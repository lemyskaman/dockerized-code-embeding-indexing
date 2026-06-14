## ADDED Requirements

### Requirement: Compose overlay services
The system SHALL define `postgres`, `vector-stack`, and `aspire-dashboard` services in `docker-compose.override.yaml`.

#### Scenario: Services are added by override
- **WHEN** `docker compose config` is run in a host project with the toolkit installed
- **THEN** the final merged configuration contains `postgres`, `vector-stack`, and `aspire-dashboard`

### Requirement: Host compose file remains unchanged
The system SHALL not require edits to the host project's base `docker-compose.yaml`.

#### Scenario: Base compose file is untouched
- **WHEN** the toolkit is activated
- **THEN** the host project's base `docker-compose.yaml` remains unchanged and the AI services come only from `docker-compose.override.yaml`

### Requirement: Shared application network
The system SHALL define an `app-network` bridge network for `postgres`, `vector-stack`, and `aspire-dashboard`.

#### Scenario: Services share a network
- **WHEN** the stack starts
- **THEN** `postgres`, `vector-stack`, and `aspire-dashboard` are attached to the same Docker network

### Requirement: External persistence volumes
The system SHALL declare external named volumes for `pgdata`, `qdrant-storage`, and `aperio-cache`.

#### Scenario: Volumes survive compose down
- **WHEN** `docker compose down` is run without `-v`
- **THEN** `pgdata`, `qdrant-storage`, and `aperio-cache` remain available for the next startup

### Requirement: Host Ollama connectivity
The system SHALL configure `vector-stack` to reach host Ollama through `host.docker.internal:11434`, with `OLLAMA_HOST_IP` override support.

#### Scenario: Linux host gateway connectivity
- **WHEN** Docker supports `host-gateway`
- **THEN** `vector-stack` can call `http://host.docker.internal:11434/api/tags` without setting `OLLAMA_HOST_IP`

#### Scenario: Rancher or Lima override connectivity
- **WHEN** `OLLAMA_HOST_IP` is set to the host LAN IP
- **THEN** `host.docker.internal` resolves to that IP inside `vector-stack`

### Requirement: Read-only workspace mount
The system SHALL mount the host workspace directory read-only into `vector-stack` at `/workspace`.

#### Scenario: MCP servers can read source files
- **WHEN** a project exists under the configured workspace path
- **THEN** MCP servers can read files under `/workspace`

#### Scenario: MCP servers cannot modify source through mount
- **WHEN** an MCP server attempts to write through `/workspace`
- **THEN** the filesystem mount prevents the write
