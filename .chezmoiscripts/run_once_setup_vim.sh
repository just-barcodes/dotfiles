#!/bin/bash
set -euo pipefail

if ! command -v vim >/dev/null 2>&1; then
	echo "vim not installed; skipping :PluginInstall"
	exit 0
fi

if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
	echo "Vundle not present at ~/.vim/bundle/Vundle.vim; skipping :PluginInstall"
	echo "  bootstrap with: git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim"
	exit 0
fi

echo "Running :PluginInstall in vim"
vim +PluginInstall +qall
echo "Done!"
