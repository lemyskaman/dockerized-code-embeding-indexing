## ADDED Requirements

### Requirement: qdrant-mcp-server configuration
The system SHALL configure qdrant-mcp-server to connect to local Qdrant and host Ollama through wrapper environment variables.

#### Scenario: qdrant connects to Qdrant
- **WHEN** `mcp-qdrant` starts
- **THEN** it connects to Qdrant at `http://127.0.0.1:6333`

#### Scenario: qdrant embeds through Ollama
- **WHEN** `mcp-qdrant` needs embeddings
- **THEN** it calls Ollama through `http://host.docker.internal:11434`

### Requirement: Code indexing tools
The system SHALL expose qdrant-mcp-server code tools including `index_codebase`, `search_code`, `reindex_changes`, and `index_git_history`.

#### Scenario: Codebase can be indexed
- **WHEN** an AI client invokes `index_codebase` with a valid path
- **THEN** source files are parsed, chunked, embedded, and stored in Qdrant

#### Scenario: Code can be searched semantically
- **WHEN** an AI client invokes `search_code` with a natural language query
- **THEN** matching code chunks are returned with file paths and scores

#### Scenario: Changed files can be reindexed
- **WHEN** an AI client invokes `reindex_changes`
- **THEN** changed files are detected and only those changes are reindexed

### Requirement: Collection management tools
The system SHALL expose `create_collection`, `list_collections`, and `delete_collection` through qdrant-mcp-server.

#### Scenario: Collections can be listed
- **WHEN** an AI client invokes `list_collections`
- **THEN** existing Qdrant collections are returned

#### Scenario: New collection can be created
- **WHEN** an AI client invokes `create_collection` with a valid name and vector size
- **THEN** the Qdrant collection is created

### Requirement: Qdrant compatibility fix
The system SHALL use qdrant-mcp-server v3.3.5+ so `checkCompatibility: false` is inherited upstream.

#### Scenario: Qdrant v1.16.3 is accepted
- **WHEN** Qdrant v1.16.3 is running
- **THEN** `mcp-qdrant` starts without a client/server version mismatch error

### Requirement: Ollama chunk overflow prevention
The system SHALL keep `CODE_CHUNK_SIZE=1500` for qdrant-mcp-server and rely on v3.3.5+ 3800-character truncation.

#### Scenario: Large code chunks do not silently drop
- **WHEN** indexing encounters chunks that exceed Ollama's effective context
- **THEN** qdrant-mcp-server truncates oversized embedding input and indexes the batch instead of silently storing zero documents

### Requirement: mxbai separate collection path
The system SHALL require a separate Qdrant collection when evaluating `mxbai-embed-large`.

#### Scenario: mxbai does not reuse nomic indexes
- **WHEN** `mxbai-embed-large` is selected
- **THEN** a new collection with 1024-dimensional vectors is created instead of reusing a 768-dimensional nomic collection
