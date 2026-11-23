#!/usr/bin/env bash
# Set up dotfiles on this machine. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$HOME/.venvs/pdf2md"

# 1. System packages
need=()
for pkg in python3 poppler-utils libnotify; do
    rpm -q "$pkg" >/dev/null 2>&1 || need+=("$pkg")
done
if (( ${#need[@]} )); then
    sudo dnf install -y "${need[@]}"
fi

# 2. pdf2md venv: rebuilt if missing or broken by a Python upgrade
if ! "$VENV/bin/python" -c "import pymupdf4llm" >/dev/null 2>&1; then
    echo "Building $VENV"
    rm -rf "$VENV"
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet -r "$DOTFILES/pdf2md-requirements.txt"
fi

# 3. Symlinks: never overwrite a real file
link() {
    local src="$1" dest="$2"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        echo "Skipped $dest: a real file is there, move it first"
        return
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    echo "Linked $dest"
}

for script in "$DOTFILES"/bin/*; do
    link "$script" "$HOME/.local/bin/$(basename "$script")"
done
link "$DOTFILES/nautilus/PDF" "$HOME/.local/share/nautilus/scripts/PDF"
