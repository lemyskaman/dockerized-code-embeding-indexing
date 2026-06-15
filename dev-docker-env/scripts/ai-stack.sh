#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.override.yaml"
QDRANT_URL="${QDRANT_URL:-http://localhost:26333}"

die() { echo "[ai-stack] ERROR: $*" >&2; exit 1; }
info() { echo "[ai-stack] $*" >&2; }

require_yes() {
  local action="$1"
  if [[ "${YES:-}" != "true" ]]; then
    echo "[ai-stack] This action ($action) is destructive and requires --yes." >&2
    exit 1
  fi
}

qdrant_collections() {
  curl -sf "${QDRANT_URL}/collections" | jq -r '.result.collections[].name' 2>/dev/null || true
}

qdrant_delete_collection() {
  local name="$1"
  local http_status
  http_status="$(curl -sf -o /dev/null -w '%{http_code}' -X DELETE "${QDRANT_URL}/collections/${name}")"
  if [[ "$http_status" == "200" ]]; then
    info "  Deleted collection: $name"
  else
    info "  Warning: DELETE ${name} -> HTTP ${http_status}"
  fi
}

cmd_status() {
  echo ""
  echo "=== Qdrant health ==="
  local qdrant_info
  qdrant_info="$(curl -sf --max-time 5 "${QDRANT_URL}/" 2>/dev/null)" || {
    echo "(Qdrant not reachable at ${QDRANT_URL})"
    qdrant_info=""
  }
  if [[ -n "$qdrant_info" ]]; then
    echo "  version : $(echo "$qdrant_info" | jq -r '.version // "unknown"')"
    echo "  status  : OK"
  fi

  echo ""
  echo "=== Collections ==="
  local cols col info_json count
  cols="$(qdrant_collections)"
  if [[ -z "$cols" ]]; then
    echo "  (none)"
  else
    while IFS= read -r col; do
      info_json="$(curl -sf "${QDRANT_URL}/collections/${col}" 2>/dev/null || echo '{}')"
      count="$(echo "$info_json" | jq -r '.result.points_count // "?"')"
      echo "  $col  ($count vectors)"
    done <<< "$cols"
  fi

  echo ""
  echo "=== Aperio configuration ==="
  echo "  DB_BACKEND: postgres"
  echo "  DATABASE_URL: postgresql://aperio:aperio_local@postgres:5432/aperio"
  echo ""
  echo "=== Aperio tools ==="
  docker exec -i vector-stack mcp-aperio <<'JSON' | tail -n 1 | jq -r '.result.tools[]?.name' | paste -sd ', ' -
{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
JSON

  echo ""
  echo "=== Container state ==="
  cd "$REPO_ROOT"
  docker compose -f "$COMPOSE_FILE" ps vector-stack postgres aspire-dashboard 2>/dev/null || echo "  compose ps failed"
}

cmd_reset_soft() {
  info "Soft reset: clearing all Qdrant collections..."
  local cols col
  cols="$(qdrant_collections)"
  if [[ -z "$cols" ]]; then
    info "No collections found; nothing to delete."
    return
  fi
  while IFS= read -r col; do
    qdrant_delete_collection "$col"
  done <<< "$cols"
  info "Soft reset complete."
}

cmd_reset_hard() {
  require_yes "hard reset (removes qdrant-storage and aperio-cache volumes)"

  cd "$REPO_ROOT"
  info "Stopping vector-stack..."
  docker compose -f "$COMPOSE_FILE" stop vector-stack 2>/dev/null || true
  docker compose -f "$COMPOSE_FILE" rm -f vector-stack 2>/dev/null || true

  info "Removing volumes: qdrant-storage, aperio-cache..."
  docker volume rm qdrant-storage aperio-cache 2>/dev/null || true

  info "Recreating volumes..."
  docker volume create qdrant-storage
  docker volume create aperio-cache

  info "Starting vector-stack..."
  docker compose -f "$COMPOSE_FILE" up -d vector-stack
  info "Hard reset complete."
}

cmd_reset_memory() {
  require_yes "memory reset (truncates Aperio memory and wiki tables)"

  info "Truncating Aperio memory and wiki tables..."
  docker compose -f "$COMPOSE_FILE" exec -T postgres psql -U aperio -d aperio <<'SQL'
TRUNCATE TABLE memories, wiki_articles, wiki_article_revisions, wiki_article_sources RESTART IDENTITY CASCADE;
SQL
  info "Memory reset complete."
}

cmd_reindex() {
  local workspace="${1:?'Usage: ai-stack.sh reindex <workspace-path>'}"
  info "Triggering qdrant-mcp index_codebase for: $workspace"
  python3 - "$workspace" <<'PY' | docker exec -i vector-stack mcp-qdrant
import json
import sys
workspace = sys.argv[1]
payload = {
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "index_codebase",
    "arguments": {"path": workspace},
  },
}
print(json.dumps(payload))
PY
  info "Reindex request sent."
}

CMD="${1:-}"
shift || true

HARD=false
MEMORY=false
YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hard) HARD=true; shift ;;
    --memory) MEMORY=true; shift ;;
    --yes) YES=true; shift ;;
    *) break ;;
  esac
done

export YES

case "$CMD" in
  status) cmd_status ;;
  reset)
    if [[ "$HARD" == "true" ]]; then cmd_reset_hard; fi
    if [[ "$MEMORY" == "true" ]]; then cmd_reset_memory; fi
    if [[ "$HARD" == "false" && "$MEMORY" == "false" ]]; then cmd_reset_soft; fi
    ;;
  reindex) cmd_reindex "${1:-}" ;;
  "")
    echo "Usage: ai-stack.sh <status|reset|reindex>" >&2
    echo "  status              - health, collection sizes, DB tables, container state" >&2
    echo "  reset               - soft: clear Qdrant collections" >&2
    echo "  reset --hard --yes  - hard: remove qdrant and aperio volumes and restart" >&2
    echo "  reset --memory --yes - truncate Aperio memory/wiki tables" >&2
    echo "  reindex <path>      - trigger qdrant index_codebase using /workspace path" >&2
    exit 1
    ;;
  *) die "Unknown subcommand: $CMD" ;;
esac
