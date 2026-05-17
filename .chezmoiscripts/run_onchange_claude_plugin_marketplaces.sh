#!/usr/bin/env bash
# Idempotently register Claude Code plugin marketplaces.
# Re-runs whenever this file changes (run_onchange_ prefix).

set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found; skipping plugin marketplace registration"
  exit 0
fi

existing="$(claude plugin marketplace list 2>/dev/null || true)"

ensure_marketplace() {
  local name="$1"
  local source="$2"
  if grep -qF "$name" <<<"$existing"; then
    echo "marketplace '${name}' already added"
  else
    echo "Adding marketplace '${name}'"
    claude plugin marketplace add "$source"
  fi
}

ensure_marketplace agentic-dev-team https://github.com/bdfinst/agentic-dev-team