#!/usr/bin/env bash
# Idempotently register Claude Code plugin marketplaces and install plugins
# from them. Re-runs whenever this file changes (run_onchange_ prefix).
# Marketplace names come from the marketplace's .claude-plugin/marketplace.json.

set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found; skipping plugin marketplace registration"
  exit 0
fi

existing_marketplaces="$(claude plugin marketplace list 2>/dev/null || true)"
existing_plugins="$(claude plugin list 2>/dev/null || true)"

ensure_marketplace() {
  local name="$1"
  local source="$2"
  if grep -qE "^\s*❯ ${name}\s*$" <<<"$existing_marketplaces"; then
    echo "marketplace '${name}' already added"
  else
    echo "Adding marketplace '${name}'"
    claude plugin marketplace add "$source"
  fi
}

ensure_plugin() {
  local id="$1" # <plugin>@<marketplace>
  if grep -qE "^\s*❯ ${id}\s*$" <<<"$existing_plugins"; then
    echo "plugin '${id}' already installed"
  else
    echo "Installing plugin '${id}'"
    claude plugin install "$id"
  fi
}

ensure_marketplace bfinster https://github.com/bdfinst/agentic-dev-team
ensure_plugin dev-team@bfinster
