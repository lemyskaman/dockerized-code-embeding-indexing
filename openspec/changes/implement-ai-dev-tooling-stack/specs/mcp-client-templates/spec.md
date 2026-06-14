## ADDED Requirements

### Requirement: VS Code template
The system SHALL provide a VS Code MCP template using `docker exec -i vector-stack mcp-qdrant`, `mcp-better-qdrant`, and `mcp-aperio`.

#### Scenario: VS Code template is available
- **WHEN** the toolkit files are present
- **THEN** a VS Code MCP JSON template exists under `dev-docker-env/config/mcp/`

### Requirement: Claude template
The system SHALL provide a Claude Code/Claude Desktop MCP template using the same `docker exec` transport.

#### Scenario: Claude template is available
- **WHEN** the toolkit files are present
- **THEN** a Claude MCP JSON template exists under `dev-docker-env/config/mcp/`

### Requirement: Cursor template
The system SHALL provide a Cursor MCP template using the same `docker exec` transport.

#### Scenario: Cursor template is available
- **WHEN** the toolkit files are present
- **THEN** a Cursor MCP JSON template exists under `dev-docker-env/config/mcp/`

### Requirement: stdio docker exec transport
All MCP client templates SHALL use stdio transport with `docker` as the command and `exec -i vector-stack <mcp-command>` as arguments.

#### Scenario: qdrant MCP uses docker exec
- **WHEN** an AI client loads the qdrant MCP template
- **THEN** it invokes `docker exec -i vector-stack mcp-qdrant`

#### Scenario: Aperio MCP uses docker exec
- **WHEN** an AI client loads the Aperio MCP template
- **THEN** it invokes `docker exec -i vector-stack mcp-aperio`

### Requirement: Template copy instructions
The system SHALL document where each template should be copied for VS Code, Claude Code/Claude Desktop, and Cursor.

#### Scenario: Developer can configure a client
- **WHEN** following the README
- **THEN** the developer can copy the correct template to the target client's MCP configuration path
