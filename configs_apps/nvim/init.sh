#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

echo "=== Neovim Config Setup ==="

# Set git worktree to home directory
echo "Configuring git worktree..."
git -C "$SCRIPT_DIR" config core.worktree "../../../"

# Move .config/nvim files to home (git tracks them via worktree)
if [ -d "$SCRIPT_DIR/.config/nvim" ]; then
    echo "Moving .config/nvim to ~/.config/nvim..."
    mkdir -p "$HOME_DIR/.config/nvim"
    mv "$SCRIPT_DIR/.config/nvim/"* "$HOME_DIR/.config/nvim/"
    rmdir "$SCRIPT_DIR/.config/nvim" "$SCRIPT_DIR/.config" 2>/dev/null || true
fi

# Move .local files if they exist
if [ -d "$SCRIPT_DIR/.local" ]; then
    echo "Moving .local to ~/.local..."
    mkdir -p "$HOME_DIR/.local"
    mv "$SCRIPT_DIR/.local/"* "$HOME_DIR/.local/"
    rmdir "$SCRIPT_DIR/.local" 2>/dev/null || true
fi

echo ""
echo "Setup complete!"
echo "Files are now in ~/.config/nvim and tracked by git via worktree."
echo ""
echo "Next steps:"
echo "  1. Install vim-plug: https://github.com/junegunn/vim-plug"
echo "  2. Open neovim and run :PlugInstall"
echo "  3. Install LSP servers (ruff, pyright, typescript-language-server, etc.)"
