## ADDED Requirements

### Requirement: Host Ollama prerequisite
The system SHALL require Ollama to be installed on the host before the stack is used.

#### Scenario: Ollama is available
- **WHEN** setup validation runs
- **THEN** `ollama --version` succeeds on the host

### Requirement: Default embedding model
The system SHALL use `nomic-embed-text:v1.5` as the default Ollama embedding model for qdrant-mcp-server and better-qdrant-mcp-server.

#### Scenario: nomic model is configured
- **WHEN** `mcp-qdrant` starts
- **THEN** its embedding model is `nomic-embed-text:v1.5`

### Requirement: Default chat model
The system SHALL use `qwen2.5:3b` as the default Ollama chat model for Aperio.

#### Scenario: Aperio chat model is configured
- **WHEN** `mcp-aperio` starts
- **THEN** its Ollama model is `qwen2.5:3b`

### Requirement: Model pull guidance
The system SHALL document the required `ollama pull` commands for `nomic-embed-text:v1.5` and `qwen2.5:3b`.

#### Scenario: Developer can pull required models
- **WHEN** following the README setup steps
- **THEN** the developer can pull both required Ollama models

### Requirement: mxbai optional model path
The system SHALL document `mxbai-embed-large` as an optional embedding model with 1024 dimensions, 512-token context, stricter chunking, and separate Qdrant collections.

#### Scenario: mxbai evaluation is isolated
- **WHEN** a developer chooses `mxbai-embed-large`
- **THEN** the documentation directs them to create a separate 1024-dimensional collection and use stricter chunking

### Requirement: Ollama connectivity verification
The system SHALL provide a command or script step to verify container-to-host Ollama connectivity.

#### Scenario: Ollama connectivity can be verified
- **WHEN** the stack is running
- **THEN** `curl http://host.docker.internal:11434/api/tags` from `vector-stack` returns model information
