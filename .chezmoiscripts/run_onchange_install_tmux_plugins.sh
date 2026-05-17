#!/usr/bin/env bash
# Install / update tmux plugins (manual, no TPM).
# Bump the version comment below to force chezmoi to re-run this script.
# tmux-devcontainers: just-barcodes/tmux-devcontainers @ main (v1)

set -euo pipefail

plugins_dir="${HOME}/.tmux/plugins"
mkdir -p "${plugins_dir}"

clone_or_update() {
  local repo_url="$1"
  local dest="$2"

  if [ -d "${dest}/.git" ]; then
    if ! git -C "${dest}" pull --ff-only; then
      echo "ff-only pull failed for ${dest}; re-cloning"
      rm -rf "${dest}"
      git clone --depth 1 "${repo_url}" "${dest}"
    fi
  else
    git clone --depth 1 "${repo_url}" "${dest}"
  fi
}

clone_or_update \
  "https://github.com/just-barcodes/tmux-devcontainers.git" \
  "${plugins_dir}/tmux-devcontainers"