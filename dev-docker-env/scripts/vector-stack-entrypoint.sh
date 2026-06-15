#!/usr/bin/env bash
set -euo pipefail

echo "[vector-stack] Starting Qdrant..."
cd /qdrant
./entrypoint.sh &
QDRANT_PID=$!

echo "[vector-stack] Waiting for Qdrant to be healthy on 127.0.0.1:6333..."
until curl -sf http://127.0.0.1:6333/healthz >/dev/null 2>&1; do
  if ! kill -0 "$QDRANT_PID" 2>/dev/null; then
    echo "[vector-stack] ERROR: Qdrant exited before becoming healthy" >&2
    exit 1
  fi
  sleep 1
done

echo "[vector-stack] Qdrant is ready."
wait "$QDRANT_PID"
