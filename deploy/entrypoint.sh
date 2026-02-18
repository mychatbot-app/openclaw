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

# Skip device auth for internal tool calls (Cloud Run has no persistent device identity)
export OPENCLAW_SKIP_DEVICE_AUTH=1

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
    MODELS_JSON='"openrouter/anthropic/claude-sonnet-4.6": { "label": "Claude Sonnet 4.6" }'
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
      "allowInsecureAuth": true
    },
    "http": {
      "endpoints": {
        "chatCompletions": {
          "enabled": true
        }
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-sonnet-4.6"
      }
    },
    "list": [
      {
        "id": "main",
        "identity": {
          "name": "Agent"
        }
      }
    ]
  },
  "tools": {
    "web": {
      "search": {
        "provider": "perplexity",
        "perplexity": {
          "model": "perplexity/sonar"
        }
      }
    }
  }
}
JSONEOF

  echo "[entrypoint] Config written to $CONFIG_FILE"

  # Write auth-profiles.json with API keys
  AGENT_DIR="$OPENCLAW_DIR/agents/main/agent"
  mkdir -p "$AGENT_DIR"
  AUTH_FILE="$AGENT_DIR/auth-profiles.json"

  AUTH_PROFILES='{"version":1,"profiles":{},"lastGood":{}}'
  if [ -n "$OPENROUTER_API_KEY" ]; then
    AUTH_PROFILES=$(echo "$AUTH_PROFILES" | node -e "
const fs = require('fs');
const d = JSON.parse(fs.readFileSync('/dev/stdin','utf8'));
d.profiles['openrouter:default'] = {provider:'openrouter',type:'api_key',key:'$OPENROUTER_API_KEY'};
d.lastGood['openrouter'] = 'openrouter:default';
process.stdout.write(JSON.stringify(d));
")
  fi
  if [ -n "$OPENAI_API_KEY" ]; then
    AUTH_PROFILES=$(echo "$AUTH_PROFILES" | node -e "
const fs = require('fs');
const d = JSON.parse(fs.readFileSync('/dev/stdin','utf8'));
d.profiles['openai:default'] = {provider:'openai',type:'api_key',key:'$OPENAI_API_KEY'};
d.lastGood['openai'] = 'openai:default';
process.stdout.write(JSON.stringify(d));
")
  fi
  echo "$AUTH_PROFILES" > "$AUTH_FILE"
  echo "[entrypoint] Auth profiles written to $AUTH_FILE"

  # Install skills with account-specific config
  SKILLS_DIR="$WORKSPACE_DIR/skills"
  mkdir -p "$SKILLS_DIR"

  # Copy bundled skills and substitute env vars
  if [ -d "/opt/openclaw-skills" ]; then
    for skill_dir in /opt/openclaw-skills/*/; do
      skill_name=$(basename "$skill_dir")
      target_dir="$SKILLS_DIR/$skill_name"
      mkdir -p "$target_dir"
      for f in "$skill_dir"*; do
        [ -f "$f" ] || continue
        # Substitute env vars in skill files
        MCB_MCP_URL="${MCB_MCP_BASE_URL:-https://api.mychatbot.app}/api/mcp/sales-management?account_id=${MCB_ACCOUNT_ID:-unknown}"
        sed "s|\${MCB_ACCOUNT_ID}|${MCB_ACCOUNT_ID:-unknown}|g; s|\${MCB_MCP_URL}|${MCB_MCP_URL}|g" "$f" > "$target_dir/$(basename "$f")"
      done
      echo "[entrypoint] Installed skill: $skill_name"
    done
  fi

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
  echo "[entrypoint] Existing config found, updating token + endpoints"
  # Always update the gateway token from env (re-deploy generates new tokens)
  if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
if (!cfg.gateway) cfg.gateway = {};
if (!cfg.gateway.auth) cfg.gateway.auth = {};
cfg.gateway.auth.mode = 'token';
cfg.gateway.auth.token = '$OPENCLAW_GATEWAY_TOKEN';
if (!cfg.gateway.http) cfg.gateway.http = {};
if (!cfg.gateway.http.endpoints) cfg.gateway.http.endpoints = {};
if (!cfg.gateway.http.endpoints.chatCompletions) cfg.gateway.http.endpoints.chatCompletions = {};
cfg.gateway.http.endpoints.chatCompletions.enabled = true;
if (!cfg.gateway.controlUi) cfg.gateway.controlUi = {};
cfg.gateway.controlUi.allowInsecureAuth = true;
fs.writeFileSync('$CONFIG_FILE', JSON.stringify(cfg, null, 2));
console.log('[entrypoint] Updated token, chatCompletions, and allowInsecureAuth');
" || echo "[entrypoint] Warning: failed to update config"
  fi

  # Always update auth-profiles with API keys from env (in case keys rotated)
  AGENT_DIR="$OPENCLAW_DIR/agents/main/agent"
  mkdir -p "$AGENT_DIR"
  AUTH_FILE="$AGENT_DIR/auth-profiles.json"
  if [ -n "${OPENROUTER_API_KEY:-}" ] && [ -f "$AUTH_FILE" ]; then
    node -e "
const fs = require('fs');
const d = JSON.parse(fs.readFileSync('$AUTH_FILE','utf8'));
d.profiles['openrouter:default'] = {provider:'openrouter',type:'api_key',key:'${OPENROUTER_API_KEY}'};
d.lastGood['openrouter'] = 'openrouter:default';
fs.writeFileSync('$AUTH_FILE', JSON.stringify(d, null, 2));
console.log('[entrypoint] Updated OpenRouter key in auth-profiles');
" || echo "[entrypoint] Warning: failed to update auth-profiles"
  fi
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
