# dotfiles

Personal scripts and configuration for Fedora (GNOME).

## Contents

- `bin/pdf2md`: converts PDFs to Markdown beside the original (PyMuPDF4LLM, in a venv)
- `bin/pdf2png`: converts PDFs to PNG at 150 DPI (poppler)
- `nautilus/PDF`: right-click actions in Files for both, with desktop notifications

## Setup

    git clone <repo-url> ~/Projects/dotfiles
    ~/Projects/dotfiles/install.sh

Re-run `install.sh` after a Fedora upgrade that changes the Python version. It rebuilds the venv.
