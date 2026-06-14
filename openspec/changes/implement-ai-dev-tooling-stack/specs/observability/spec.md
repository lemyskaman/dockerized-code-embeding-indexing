## ADDED Requirements

### Requirement: Aspire Dashboard service
The system SHALL define an `aspire-dashboard` service using the Microsoft Aspire Dashboard image.

#### Scenario: Dashboard service exists
- **WHEN** `docker compose config` is run
- **THEN** the final configuration contains the `aspire-dashboard` service

### Requirement: Dashboard ports
The system SHALL expose Aspire Dashboard on host port `18888` for HTTP and host port `18889` for the OTLP gRPC receiver.

#### Scenario: Dashboard web UI is reachable
- **WHEN** the stack is running
- **THEN** the dashboard UI is reachable at `http://localhost:18888`

#### Scenario: OTLP receiver is reachable
- **WHEN** the stack is running
- **THEN** the OTLP gRPC receiver is reachable on host port `18889`

### Requirement: Unsecured local dashboard
The system SHALL configure Aspire Dashboard for local unsecured access.

#### Scenario: Dashboard opens without authentication
- **WHEN** a developer opens `http://localhost:18888`
- **THEN** the dashboard UI loads without requiring credentials

### Requirement: OTLP configuration guidance
The system SHALL document the environment variables required for services that send telemetry: `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, and `OTEL_LOGS_EXPORTER`.

#### Scenario: Service can send telemetry
- **WHEN** a service sets `OTEL_EXPORTER_OTLP_ENDPOINT=http://aspire-dashboard:18889`
- **THEN** telemetry is sent to the Aspire Dashboard receiver
