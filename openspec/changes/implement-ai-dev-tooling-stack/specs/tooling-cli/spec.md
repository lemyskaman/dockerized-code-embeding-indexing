## ADDED Requirements

### Requirement: start script
The system SHALL provide `dev-docker-env/scripts/start.sh` for one-command startup.

#### Scenario: start script creates volumes
- **WHEN** `start.sh` is run before first startup
- **THEN** it creates missing external volumes before running `docker compose up`

#### Scenario: start script starts stack
- **WHEN** `start.sh` is run
- **THEN** the Docker Compose stack starts successfully

### Requirement: ai-stack CLI
The system SHALL provide `dev-docker-env/scripts/ai-stack.sh` with `status`, `reset`, and `reindex` commands.

#### Scenario: status command reports health
- **WHEN** `ai-stack.sh status` is run while the stack is running
- **THEN** it reports service health and available Qdrant collections

#### Scenario: reset command clears selected state
- **WHEN** `ai-stack.sh reset` is run with a valid reset mode
- **THEN** it removes the intended Qdrant, memory, or cache state without deleting unrelated project files

#### Scenario: reindex command indexes a path
- **WHEN** `ai-stack.sh reindex <path>` is run
- **THEN** qdrant-mcp-server indexes the requested path

### Requirement: vector-stack entrypoint
The system SHALL provide `dev-docker-env/scripts/vector-stack-entrypoint.sh` or equivalent entrypoint logic.

#### Scenario: entrypoint waits for Qdrant
- **WHEN** the container starts
- **THEN** the entrypoint waits until Qdrant is healthy before keeping the container running

### Requirement: environment template
The system SHALL provide `dev-docker-env/config/env/.env.example` with `OLLAMA_HOST_IP`, workspace path, and stack configuration variables.

#### Scenario: developer can copy environment template
- **WHEN** a developer copies `.env.example` to `.env`
- **THEN** the file contains documented placeholders for required configuration

### Requirement: executable scripts
All shell scripts SHALL be executable.

#### Scenario: scripts can be invoked directly
- **WHEN** a developer runs `./dev-docker-env/scripts/start.sh`
- **THEN** the script executes without requiring `sh start.sh`
