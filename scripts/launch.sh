#!/usr/bin/env bash
# Launches the shortcuts-mcp server with whichever runtime is available.
# Bun runs src/server.ts directly (no compile step needed);
# node runs the tsc-compiled dist/server.js.
set -euo pipefail

: "${CLAUDE_PLUGIN_ROOT:?CLAUDE_PLUGIN_ROOT not set}"
: "${CLAUDE_PLUGIN_DATA:?CLAUDE_PLUGIN_DATA not set}"

export NODE_PATH="${CLAUDE_PLUGIN_DATA}/node_modules"

if command -v bun >/dev/null 2>&1; then
  exec bun "${CLAUDE_PLUGIN_ROOT}/src/server.ts"
fi

exec node "${CLAUDE_PLUGIN_ROOT}/dist/server.js"
