#!/bin/bash
set -euo pipefail

# MyChatBot OpenClaw Agent Entrypoint
# Generates openclaw.json from environment variables on first boot.
# Subsequent boots reuse the existing config (persisted via GCS mount).

OPENCLAW_DIR="${OPENCLAW_STATE_DIR:-/home/node/.openclaw}"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace"

echo "[entrypoint] OpenClaw agent starting..."
echo "[entrypoint] State dir: $OPENCLAW_DIR"

# Ensure directories exist
mkdir -p "$OPENCLAW_DIR" "$WORKSPACE_DIR"

# Symlink ~/.openclaw → state dir so OpenClaw finds its config
HOME_OPENCLAW="/home/node/.openclaw"
if [ "$OPENCLAW_DIR" != "$HOME_OPENCLAW" ]; then
  rm -rf "$HOME_OPENCLAW" 2>/dev/null || true
  mkdir -p "$(dirname "$HOME_OPENCLAW")"
  ln -sf "$OPENCLAW_DIR" "$HOME_OPENCLAW"
  echo "[entrypoint] Symlinked $HOME_OPENCLAW → $OPENCLAW_DIR"
fi

# Generate config on first boot only
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[entrypoint] First boot — generating openclaw.json"

  # Required env vars
  : "${OPENCLAW_GATEWAY_TOKEN:?OPENCLAW_GATEWAY_TOKEN is required}"

  # Optional env vars with defaults
  OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}"
  OPENAI_API_KEY="${OPENAI_API_KEY:-}"
  MCB_ACCOUNT_ID="${MCB_ACCOUNT_ID:-}"
  MCB_CORS_ORIGIN="${MCB_CORS_ORIGIN:-https://app.mychatbot.app}"

  # Build model providers based on available keys
  MODELS_JSON=""
  if [ -n "$OPENROUTER_API_KEY" ]; then
    MODELS_JSON='"openrouter/anthropic/claude-sonnet-4": { "label": "Claude Sonnet 4" }'
  fi
  if [ -n "$OPENAI_API_KEY" ]; then
    if [ -n "$MODELS_JSON" ]; then
      MODELS_JSON="$MODELS_JSON,"
    fi
    MODELS_JSON="$MODELS_JSON \"openai/gpt-4.1-mini\": { \"label\": \"GPT-4.1 Mini\" }"
  fi

  cat > "$CONFIG_FILE" << JSONEOF
{
  "gateway": {
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "$OPENCLAW_GATEWAY_TOKEN"
    },
    "controlUi": {
      "allowedOrigins": ["$MCB_CORS_ORIGIN"],
      "allowInsecureAuth": false
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-sonnet-4"
      }
    }
  }
}
JSONEOF

  echo "[entrypoint] Config written to $CONFIG_FILE"

  # Create default workspace files
  if [ ! -f "$WORKSPACE_DIR/SOUL.md" ]; then
    cat > "$WORKSPACE_DIR/SOUL.md" << 'SOULEOF'
# SOUL.md

You are a personal AI agent deployed by MyChatBot.
You're helpful, resourceful, and proactive.
Be concise when needed, thorough when it matters.
SOULEOF
    echo "[entrypoint] Created default SOUL.md"
  fi

  if [ ! -f "$WORKSPACE_DIR/MEMORY.md" ]; then
    cat > "$WORKSPACE_DIR/MEMORY.md" << 'MEMEOF'
# MEMORY.md

_No memories yet. This file will grow as you learn._
MEMEOF
    echo "[entrypoint] Created default MEMORY.md"
  fi

else
  echo "[entrypoint] Existing config found, using it"
fi

echo "[entrypoint] Starting OpenClaw gateway..."

# Cloud Run sets PORT env var (usually 8080). OpenClaw uses OPENCLAW_GATEWAY_PORT.
# Map PORT → OPENCLAW_GATEWAY_PORT if set and not already overridden.
if [ -n "${PORT:-}" ] && [ -z "${OPENCLAW_GATEWAY_PORT:-}" ]; then
  export OPENCLAW_GATEWAY_PORT="$PORT"
  echo "[entrypoint] Using Cloud Run PORT=$PORT as gateway port"
fi

# Start the gateway
# --allow-unconfigured: allows first-time boot without interactive setup
exec node openclaw.mjs gateway --allow-unconfigured
