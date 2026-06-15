#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
NSV_FILE="$REPO_ROOT/.nsv"
COMPOSE_FILE="$REPO_ROOT/docker-compose.override.yaml"
INDEX_PATH="${INDEX_PATH:-/workspace}"
SKIP_INDEX=false

for arg in "$@"; do
  case "$arg" in
    --skip-index) SKIP_INDEX=true ;;
    --index-path=*) INDEX_PATH="${1#*=}" ;;
    *) echo "[start] Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

info() { echo "[start] $*"; }
sep() { echo ""; echo "────────────────────────────────────────────"; }

load_local_env() {
  [[ -f "$ENV_FILE" ]] || return 0
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"
      value="${value%\"}"
      value="${value#\"}"
      if [[ -z "${!key:-}" ]]; then
        export "$key=$value"
      fi
    fi
  done < "$ENV_FILE"
}

read_nsv_value() {
  local key="$1"
  [[ -f "$NSV_FILE" ]] || return 1
  if command -v jq >/dev/null 2>&1 && jq -e . "$NSV_FILE" >/dev/null 2>&1; then
    jq -r --arg key "$key" '.[$key] // empty' "$NSV_FILE" 2>/dev/null | sed '/^$/d' | head -n 1
    return 0
  fi
  awk -v key="$key" '
    BEGIN { FS="[=:]" }
    {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
      gsub(/^["'"'"']|["'"'"']$/, "", $2)
      if ($1 == key && $2 != "") { print $2; exit }
    }
  ' "$NSV_FILE"
}

normalize_path() {
  local path="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$path" 2>/dev/null || printf '%s\n' "$path"
    return
  fi

  if [[ -e "$path" || -L "$path" ]]; then
    (cd "$(dirname "$path")" && printf '%s/%s\n' "$(pwd -P)" "$(basename "$path")")
  else
    printf '%s\n' "$path"
  fi
}

resolve_workspace() {
  if [[ -n "${WORKSPACE_PATH:-}" ]]; then
    echo "$WORKSPACE_PATH"
    return
  fi

  local nsv_workspace
  nsv_workspace="$(read_nsv_value workspace_path || true)"
  if [[ -n "$nsv_workspace" ]]; then
    echo "$nsv_workspace"
    return
  fi

  if [[ -n "${REPOSITORY_ROOT:-}" ]]; then
    echo "$REPOSITORY_ROOT"
    return
  fi

  local nsv_repo_root
  nsv_repo_root="$(read_nsv_value repository_root || true)"
  if [[ -n "$nsv_repo_root" ]]; then
    echo "$nsv_repo_root"
    return
  fi

  if [[ -d "$REPO_ROOT/src" ]]; then
    echo "$REPO_ROOT/src"
  elif [[ -d "${HOME}/projects" ]]; then
    echo "${HOME}/projects"
  else
    echo "$REPO_ROOT"
  fi
}

ensure_volume() {
  local volume_name="$1"
  if docker volume inspect "$volume_name" >/dev/null 2>&1; then
    info "Volume already exists: $volume_name"
  else
    info "Creating volume: $volume_name"
    docker volume create "$volume_name" >/dev/null
  fi
}

load_local_env
WORKSPACE_PATH="$(normalize_path "$(resolve_workspace)")"
export WORKSPACE_PATH

sep
info "Repository root: $REPO_ROOT"
info "Workspace mount: $WORKSPACE_PATH -> /workspace:ro"

sep
info "Ensuring required external Docker volumes exist"
ensure_volume pgdata
ensure_volume qdrant-storage
ensure_volume aperio-cache

sep
info "Starting Docker Compose services"
cd "$REPO_ROOT"
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans

ensure_ollama_reachable() {
  if docker exec vector-stack curl -sf --max-time 5 http://host.docker.internal:11434/api/tags >/dev/null 2>&1; then
    info "Ollama is reachable through host.docker.internal"
    return 0
  fi

  if [[ -n "${OLLAMA_HOST_IP:-}" ]]; then
    fail "Ollama is not reachable through OLLAMA_HOST_IP=${OLLAMA_HOST_IP}"
  fi

  local detected_ip
  detected_ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || true)"
  if [[ -n "$detected_ip" ]]; then
    info "host.docker.internal failed; recreating vector-stack with OLLAMA_HOST_IP=${detected_ip}"
    OLLAMA_HOST_IP="$detected_ip" docker compose -f "$COMPOSE_FILE" up -d --force-recreate vector-stack
    docker exec vector-stack curl -sf --max-time 10 "http://${detected_ip}:11434/api/tags" >/dev/null || fail "Ollama is not reachable at ${detected_ip}:11434"
    info "Ollama is reachable through ${detected_ip}"
    return 0
  fi

  fail "Ollama is not reachable from vector-stack"
}

sep
ensure_ollama_reachable

sep
if [[ "$SKIP_INDEX" == "true" ]]; then
  info "Skipping qdrant index (--skip-index)"
else
  info "Indexing workspace into Qdrant"
  bash "$SCRIPT_DIR/ai-stack.sh" reindex "$INDEX_PATH"
fi

sep
echo ""
echo "  Qdrant REST   http://localhost:26333"
echo "  Qdrant gRPC   localhost:26334"
echo "  Postgres      localhost:25432"
echo "  Aspire        http://localhost:28888"
echo ""
echo "  Stop:  docker compose down"
echo "  Logs:  docker compose logs -f vector-stack postgres aspire-dashboard"
echo ""
