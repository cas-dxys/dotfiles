# dotfiles

Personal scripts and configuration for Fedora (GNOME). Last tested on Fedora 45 with Python 3.15.

The real files live in this repo, and `install.sh` symlinks them into place, so editing a file here takes effect immediately.

## Setup

```bash
git clone https://github.com/cas-dxys/dotfiles.git ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

The clone can live anywhere, because `install.sh` works out its own location. `install.sh` is safe to re-run at any time. It:

1. Installs any missing system packages with dnf.
2. Builds the Python venvs that scripts need, or rebuilds them if they're missing or broken. A venv breaks when Fedora upgrades the Python version.
3. Symlinks everything into place. It never overwrites a real file: if one is in the way, it skips that link and says so.

## Layout

```
dotfiles/
├── .gitignore              # allowlist: everything is ignored unless listed
├── LICENSE                 # GPL-3.0
├── README.md
├── install.sh              # setup script
├── pdf2md-requirements.txt # pinned Python packages for pdf2md
├── bin/                    # scripts, linked into ~/.local/bin
└── nautilus/               # right-click actions for Files
```

| Repo path       | Linked to                                  |
| --------------- | ------------------------------------------ |
| `bin/*`         | `~/.local/bin/*`                           |
| `nautilus/PDF/` | `~/.local/share/nautilus/scripts/PDF/`     |

## Scripts

### pdf2md

Converts PDFs to Markdown and saves the `.md` beside the original.

```bash
pdf2md [--replace] FILE...
```

- `--replace` overwrites an existing `.md`. Without it, existing files are skipped.
- It writes to a hidden temporary file first, then moves it into place, so a failed conversion never leaves a half-written `.md`.
- It exits with status 1 if any file fails.

**Implementation:** Python, running in its own venv at `~/.venvs/pdf2md`. The shebang is an absolute path to that venv's Python, so on a machine with a different username, change the first line to match. It converts with `pymupdf4llm.to_markdown(doc)`.

**Why a venv rather than dnf:** Fedora's `python3-PyMuPDF` package works, but it doesn't ship `pymupdf4llm`, and it's usually behind PyPI. The venv keeps the script's dependencies isolated, and deleting `~/.venvs/pdf2md` removes them completely.

**Pinned versions** (`pdf2md-requirements.txt`): `pymupdf==1.28.2` and `pymupdf4llm==0.3.4`. The reasons:

- PyMuPDF 2.x and `pymupdf_layout`, which together give layout-aware conversion, depend on packages that have no Python 3.15 builds yet. pip falls back to older releases.
- `pymupdf4llm` 2.0 on PyPI is an empty placeholder with no module inside it. Always exclude it with `!=2.0`.
- 0.3.4 has no layout analysis and prints "Consider using the pymupdf_layout package…". That message is harmless.
- `pymupdf_layout` is licensed PolyForm Noncommercial, so Fedora won't package it. The venv is the long-term approach.

**Known limitations:**

- Designed one-page PDFs, such as certificates and posters with white text on full-page shapes, can produce an empty `.md`. The text is there, but this version drops it.
- On LaTeX documents the output is good, with a few cosmetic flaws: bold split word by word, stray page numbers, and the occasional merged line.

### pdf2png

Renders PDFs to PNG at 150 DPI beside the original.

```bash
pdf2png [--replace] FILE...
```

- A single-page PDF produces `name.png`. A multi-page PDF produces a `name_png/` folder containing `name-1.png`, `name-2.png` and so on.
- It skips existing output unless `--replace` is given, renders into a hidden temporary directory, then moves the result into place.

**Implementation:** Bash, using `pdftocairo` and `pdfinfo` from `poppler-utils`.

### Files right-click actions (`nautilus/PDF/`)

In Files, right-click a PDF and choose **Scripts → PDF → Convert to MD** or **Convert to PNG**. Each action runs the matching script and shows a desktop notification: converted, already exists, or failed. It uses `notify-send` from `libnotify`.

The notification doesn't show the actual error. To see it, run the same command in a terminal.

## Maintenance

**After a Fedora upgrade**, if a Python script breaks with `ModuleNotFoundError` or "bad interpreter", run `install.sh`. It rebuilds the venv.

**Checking for the layout-aware pdf2md** (every month or so):

```bash
~/.venvs/pdf2md/bin/pip install --dry-run -U 'pymupdf4llm!=2.0' pymupdf
```

If the dry run shows `pymupdf4llm` 2.1 or later, run the same command without `--dry-run`. Test `pdf2md`, update both pins in `pdf2md-requirements.txt`, then commit. The script itself needs no changes.

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `ModuleNotFoundError` from a Python script | Fedora upgraded Python, and the venv still points at the old version's packages | Run `install.sh` |
| `bad interpreter: No such file or directory` | The venv is missing | Run `install.sh` |
| `'Document' object has no attribute 'to_markdown'` | The code calls PyMuPDF 2.x's `doc.to_markdown()`, which is missing from 1.x | Use `pymupdf4llm.to_markdown(doc)`, as the script does now |
| `No module named 'pymupdf4llm'` straight after installing it | pip chose the empty 2.0 placeholder | Reinstall with `'pymupdf4llm!=2.0'`, or use the pins in `pdf2md-requirements.txt` |
| pip tries several versions, then installs an older one | A dependency has no build for the current Python version | This is expected; keep the pins until the monthly check succeeds |
| Empty `.md` from a certificate or poster | See pdf2md's known limitations | Use `pdf2png` instead, or copy the text by hand |
| A right-click action shows "Conversion Issue" | The notification hides the actual error | Run the same command in a terminal |
| An installed command still runs the old script | Something replaced the symlink with a real file | Check with `ls -la ~/.local/bin`, move the real file out of the way, then re-run `install.sh` |

General rule: before changing anything, look at the script's shebang (`head -1`) and check what the error actually says. Most failures here are about the environment, not the code.

## Adding something new

1. Put the file in the repo. Scripts go in `bin/`; anything else gets a sensible top-level folder.
2. If it's a new top-level file or folder, add `!/name` to `.gitignore`. The allowlist is deliberate: it stops anything from being committed by accident.
3. For anything outside `bin/`, add a `link` line to `install.sh`. Add any dnf packages it needs to the package list, and add a venv block if it needs Python packages.
4. Run `./install.sh`, test it, and document it under **Scripts** above.
5. Commit and push.

Never commit secrets or machine-specific settings. Keep them in untracked files, for example a `~/.bashrc.local` that `.bashrc` sources.
