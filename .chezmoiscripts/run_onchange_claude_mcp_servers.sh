#!/usr/bin/env bash
# Idempotently register user-scope MCP servers for Claude Code.
# Re-runs whenever this file changes (run_onchange_ prefix).

set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found; skipping MCP server registration"
  exit 0
fi

existing="$(claude mcp list 2>/dev/null || true)"

ensure_mcp() {
  local name="$1"
  shift
  if grep -q "^${name}:" <<<"$existing"; then
    echo "MCP '${name}' already registered"
  else
    echo "Adding MCP '${name}'"
    claude mcp add "${name}" -s user -- "$@"
  fi
}

ensure_mcp_http() {
  local name="$1"
  local url="$2"
  if grep -q "^${name}:" <<<"$existing"; then
    echo "MCP '${name}' already registered"
  else
    echo "Adding MCP '${name}' (http)"
    claude mcp add --transport http -s user "${name}" "${url}"
  fi
}

# Always re-register so header/URL changes flow through on apply.
ensure_mcp_http_with_header() {
  local name="$1"
  local url="$2"
  local header="$3"
  claude mcp remove "${name}" -s user >/dev/null 2>&1 || true
  echo "Adding MCP '${name}' (http with header)"
  claude mcp add --transport http -s user "${name}" "${url}" --header "${header}"
}

ensure_mcp context7 npx -y @upstash/context7-mcp
# GitHub MCP uses PAT auth — token expanded from ${GITHUB_PAT} at runtime
# (set by ~/.zshrc from gnome-keyring via `secret-tool lookup service github-mcp`).
ensure_mcp_http_with_header github https://api.githubcopilot.com/mcp/ 'Authorization: Bearer ${GITHUB_PAT}'