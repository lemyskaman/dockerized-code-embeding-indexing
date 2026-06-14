## ADDED Requirements

### Requirement: better-qdrant-mcp-server installation
The system SHALL install `better-qdrant-mcp-server` as a local dependency inside `vector-stack`, not through runtime `npx`.

#### Scenario: better-qdrant starts without npx
- **WHEN** `mcp-better-qdrant` is invoked
- **THEN** it starts from the installed dependency path without fetching packages from the network

### Requirement: better-qdrant configuration
The system SHALL configure better-qdrant-mcp-server to connect to local Qdrant and host Ollama through wrapper environment variables.

#### Scenario: better-qdrant connects to Qdrant
- **WHEN** `mcp-better-qdrant` starts
- **THEN** it connects to Qdrant at `http://127.0.0.1:6333`

#### Scenario: better-qdrant embeds through Ollama
- **WHEN** `mcp-better-qdrant` needs embeddings
- **THEN** it calls Ollama through `http://host.docker.internal:11434`

### Requirement: Document ingestion tools
The system SHALL expose better-qdrant-mcp-server `add_documents` and `search` tools.

#### Scenario: Documents can be added
- **WHEN** an AI client invokes `add_documents` with text and metadata
- **THEN** the documents are embedded and stored in Qdrant

#### Scenario: Documents can be searched
- **WHEN** an AI client invokes `search` with a query
- **THEN** matching documents are returned with scores

### Requirement: Collection management tools
The system SHALL expose better-qdrant-mcp-server `list_collections` and `delete_collection` tools.

#### Scenario: better-qdrant collections can be listed
- **WHEN** an AI client invokes `list_collections`
- **THEN** collections visible to better-qdrant-mcp-server are returned

#### Scenario: better-qdrant collection can be deleted
- **WHEN** an AI client invokes `delete_collection` with a valid collection name
- **THEN** the Qdrant collection is deleted
