## ADDED Requirements

### Requirement: PostgreSQL image
The system SHALL build PostgreSQL from `postgres:18-alpine` with pgvector v0.8.1 installed.

#### Scenario: PostgreSQL starts
- **WHEN** `docker compose up -d postgres` is run
- **THEN** the PostgreSQL container starts successfully

### Requirement: pgvector version
The system SHALL use pgvector v0.8.1 or newer compatible with PostgreSQL 18.

#### Scenario: vector extension is available
- **WHEN** the database initializes
- **THEN** `CREATE EXTENSION vector` succeeds without compile-time or runtime errors

### Requirement: Aperio database initialization
The system SHALL include `01-aperio.sql` that creates the Aperio role, database, and required extensions.

#### Scenario: Aperio database exists
- **WHEN** the PostgreSQL data volume is empty and PostgreSQL starts
- **THEN** the `aperio` database and role are created automatically

### Requirement: Required PostgreSQL extensions
The system SHALL enable `vector` and `pgcrypto` extensions for the Aperio database.

#### Scenario: Extensions are enabled
- **WHEN** Aperio connects to the database
- **THEN** `vector` and `pgcrypto` extensions are available

### Requirement: PostgreSQL health check
The system SHALL define a PostgreSQL health check using `pg_isready`.

#### Scenario: vector-stack waits for PostgreSQL
- **WHEN** `docker compose up -d vector-stack` is run
- **THEN** `vector-stack` starts only after PostgreSQL reports healthy

### Requirement: External pgdata volume
The system SHALL persist PostgreSQL data in the external `pgdata` volume.

#### Scenario: Memory persists across restart
- **WHEN** a memory is stored, `docker compose down` is run, and the stack starts again
- **THEN** the memory remains available
