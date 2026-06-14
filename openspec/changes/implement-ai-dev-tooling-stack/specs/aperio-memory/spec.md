## ADDED Requirements

### Requirement: Aperio installation
The system SHALL install Aperio v0.50.1 or newer inside `vector-stack`.

#### Scenario: Aperio package is installed
- **WHEN** the image build completes
- **THEN** the installed Aperio version is v0.50.1 or newer

### Requirement: Aperio PostgreSQL configuration
The system SHALL configure Aperio to use the PostgreSQL service for memory and wiki storage.

#### Scenario: Aperio connects to PostgreSQL
- **WHEN** `mcp-aperio` starts
- **THEN** it connects to `postgres:5432` using the configured Aperio database credentials

### Requirement: Aperio Ollama chat configuration
The system SHALL configure Aperio to call host Ollama for chat and summarisation models.

#### Scenario: Aperio uses host Ollama
- **WHEN** Aperio needs chat or summarisation
- **THEN** it calls `http://host.docker.internal:11434`

### Requirement: Memory and wiki tools
The system SHALL expose Aperio memory and wiki tools including `store_memory`, `recall_memories`, `search_memories`, `forget_memory`, `create_wiki_article`, `update_wiki_article`, `search_wiki`, and `get_wiki_article`.

#### Scenario: Memory can be stored and recalled
- **WHEN** an AI client invokes `store_memory` and later `recall_memories`
- **THEN** the stored memory is returned from PostgreSQL-backed storage

#### Scenario: Wiki article can be created and searched
- **WHEN** an AI client invokes `create_wiki_article` and later `search_wiki`
- **THEN** the article is stored and discoverable through wiki search

### Requirement: File and shell tools
The system SHALL expose Aperio `read_file`, `scan_project`, and `run_shell` tools.

#### Scenario: Project files can be scanned
- **WHEN** an AI client invokes `scan_project`
- **THEN** Aperio can scan files under `/workspace`

#### Scenario: Shell commands can run in container
- **WHEN** an AI client invokes `run_shell`
- **THEN** the command runs inside `vector-stack` with controlled container access

### Requirement: LanceDB fallback documentation
The system SHALL document that Aperio can use LanceDB fallback when PostgreSQL is not configured, while the implemented stack configures PostgreSQL.

#### Scenario: PostgreSQL path is active
- **WHEN** the toolkit is started with the provided override
- **THEN** Aperio uses PostgreSQL-backed storage rather than relying on undocumented fallback behaviour
