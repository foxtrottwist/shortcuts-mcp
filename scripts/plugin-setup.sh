#!/usr/bin/env bash
# Installs runtime deps and compiles dist/ for the Claude Code plugin.
# Runs on SessionStart. Idempotent — skips install/build when inputs haven't changed.
set -euo pipefail

: "${CLAUDE_PLUGIN_ROOT:?CLAUDE_PLUGIN_ROOT not set — this script only runs from a plugin SessionStart hook}"
: "${CLAUDE_PLUGIN_DATA:?CLAUDE_PLUGIN_DATA not set}"

mkdir -p "${CLAUDE_PLUGIN_DATA}"

pkg_src="${CLAUDE_PLUGIN_ROOT}/package.json"
pkg_cached="${CLAUDE_PLUGIN_DATA}/package.json"

if ! diff -q "${pkg_src}" "${pkg_cached}" >/dev/null 2>&1; then
  echo "shortcuts-mcp: installing dependencies..."
  cp "${pkg_src}" "${CLAUDE_PLUGIN_DATA}/"
  [ -f "${CLAUDE_PLUGIN_ROOT}/pnpm-lock.yaml" ] && cp "${CLAUDE_PLUGIN_ROOT}/pnpm-lock.yaml" "${CLAUDE_PLUGIN_DATA}/"

  (
    cd "${CLAUDE_PLUGIN_DATA}"
    if command -v bun >/dev/null 2>&1; then
      bun install --silent
    elif command -v pnpm >/dev/null 2>&1; then
      pnpm install --frozen-lockfile --silent
    elif command -v npm >/dev/null 2>&1; then
      npm install --silent
    else
      echo "shortcuts-mcp: no package manager found (bun, pnpm, or npm required)" >&2
      rm -f package.json
      exit 1
    fi
  ) || { rm -f "${pkg_cached}"; exit 1; }
fi

# Symlink node_modules so runtimes find deps via the normal walk
# (belt-and-suspenders with NODE_PATH set in launch.sh).
(
  cd "${CLAUDE_PLUGIN_ROOT}"
  [ -e node_modules ] || ln -s "${CLAUDE_PLUGIN_DATA}/node_modules" node_modules
)

# Bun runs src/server.ts directly — no tsc step needed.
if command -v bun >/dev/null 2>&1; then
  echo "shortcuts-mcp: ready (bun runtime)"
  exit 0
fi

dist_entry="${CLAUDE_PLUGIN_ROOT}/dist/server.js"
src_newest="$(find "${CLAUDE_PLUGIN_ROOT}/src" -name '*.ts' -not -name '*.test.ts' -exec stat -f '%m' {} \; | sort -n | tail -1)"
dist_mtime="$(stat -f '%m' "${dist_entry}" 2>/dev/null || echo 0)"

if [ ! -f "${dist_entry}" ] || [ "${src_newest}" -gt "${dist_mtime}" ]; then
  echo "shortcuts-mcp: compiling dist/..."
  tsc_bin="${CLAUDE_PLUGIN_DATA}/node_modules/.bin/tsc"
  if [ ! -x "${tsc_bin}" ]; then
    echo "shortcuts-mcp: tsc not found at ${tsc_bin}" >&2
    exit 1
  fi
  (
    cd "${CLAUDE_PLUGIN_ROOT}"
    "${tsc_bin}"
  )
fi

echo "shortcuts-mcp: ready (node runtime)"
