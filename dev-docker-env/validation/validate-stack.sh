#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.override.yaml"
QDRANT_URL="${QDRANT_URL:-http://localhost:26333}"
OLLAMA_URL="${OLLAMA_URL:-http://host.docker.internal:11434}"
if [[ -n "${OLLAMA_HOST_IP:-}" ]]; then
  OLLAMA_URL="http://${OLLAMA_HOST_IP}:11434"
fi
START_STACK=false
REINDEX=false
MXBAI_VALIDATION=false

for arg in "$@"; do
  case "$arg" in
    --start) START_STACK=true ;;
    --reindex) REINDEX=true ;;
    --mxbai) MXBAI_VALIDATION=true ;;
    *) echo "[validate-stack] Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

info() { echo "[validate-stack] $*"; }
pass() { echo "[validate-stack] PASS: $*"; }
fail() { echo "[validate-stack] FAIL: $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_cmd docker
require_cmd curl
require_cmd jq
require_cmd python3

cd "$REPO_ROOT"

if [[ "$START_STACK" == "true" ]]; then
  info "Starting stack"
  "$SCRIPT_DIR/../scripts/start.sh" --skip-index
fi

info "Validating Docker Compose configuration"
services="$(docker compose -f "$COMPOSE_FILE" config --services)"
for service in postgres vector-stack aspire-dashboard; do
  grep -qx "$service" <<< "$services" || fail "Missing compose service: $service"
done
pass "Compose services are defined"

for volume in pgdata qdrant-storage aperio-cache; do
  docker volume inspect "$volume" >/dev/null 2>&1 || fail "Missing external volume: $volume"
done
pass "External volumes exist"

info "Validating Qdrant REST health"
curl -sf --max-time 10 "${QDRANT_URL}/healthz" >/dev/null || fail "Qdrant health check failed at ${QDRANT_URL}"
pass "Qdrant is reachable"

info "Validating PostgreSQL readiness"
docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U aperio -d aperio >/dev/null || fail "PostgreSQL is not ready"
pass "PostgreSQL is ready"

info "Validating Aspire Dashboard HTTP"
curl -sf --max-time 10 http://localhost:28888 >/dev/null || fail "Aspire Dashboard is not reachable"
pass "Aspire Dashboard is reachable"

info "Validating Ollama connectivity from vector-stack"
docker exec vector-stack curl -sf --max-time 10 "${OLLAMA_URL}/api/tags" >/dev/null || fail "Ollama is not reachable from vector-stack at ${OLLAMA_URL}"
pass "Ollama is reachable from vector-stack"

mcp_initialize() {
  local name="$1"
  local command="$2"
  info "Validating MCP server: $name"
  timeout 30 bash -c "$command" <<'JSON' >/dev/null || fail "MCP initialize failed for $name"
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"validate-stack","version":"1.0"}}}
JSON
  pass "$name initialized"
}

mcp_initialize qdrant "docker exec -i vector-stack mcp-qdrant"
mcp_initialize better-qdrant "docker exec -i vector-stack mcp-better-qdrant"
mcp_initialize aperio "docker exec -i vector-stack mcp-aperio"

if [[ "$REINDEX" == "true" ]]; then
  info "Validating code indexing"
  "$SCRIPT_DIR/../scripts/ai-stack.sh" reindex /workspace
  pass "Reindex request completed"
fi

if [[ "$MXBAI_VALIDATION" == "true" ]]; then
  info "mxbai validation requested"
  info "Create a separate 1024-dimensional collection, set EMBEDDING_MODEL=mxbai-embed-large, and reindex with CODE_CHUNK_SIZE=1000 before comparing results."
  pass "mxbai validation guidance recorded"
fi

info "Validation complete"
