#!/bin/bash
# Idempotent import of zsh/bash history into atuin's SQLite DB.
# Tracked as run_onchange so it keeps trying on later applies until atuin is
# installed (atuin dedupes on re-import, so running it more than once is safe).

set -euo pipefail

if ! command -v atuin >/dev/null 2>&1; then
	echo "atuin not installed; skipping history import"
	exit 0
fi

import_history() {
	local shell="$1"
	if ! atuin import "$shell"; then
		echo "WARN: atuin import $shell failed (exit $?); continuing" >&2
	fi
}

import_history zsh
import_history bash
