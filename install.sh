#!/usr/bin/env bash
set -euo pipefail

# MASH — Markdown Agile Sub-agent Hybrid
# Install script: curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh | bash

MASH_REPO="https://github.com/dmarchevsky/mash.git"
MARKER="<!-- MASH -->"

TARGET_DIR="$PWD"

# --- Helpers ---

info()  { printf '  \033[1;34m→\033[0m %s\n' "$1"; }
ok()    { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
warn()  { printf '  \033[1;33m!\033[0m %s\n' "$1"; }
die()   { printf '  \033[1;31m✗\033[0m %s\n' "$1" >&2; exit 1; }

# --- Step 1: Validate ---

printf '\n\033[1mMASH Installer\033[0m\n\n'

[ -d "$TARGET_DIR/.git" ] || die "Not a git repo: $TARGET_DIR"

# --- Step 2: Clone to temp dir ---

TMPDIR_MASH="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_MASH"' EXIT

info "Cloning MASH framework..."
git clone --depth 1 --quiet "$MASH_REPO" "$TMPDIR_MASH/mash"

# --- Step 3: Copy framework files (always overwrite) ---

info "Installing framework files..."
mkdir -p "$TARGET_DIR/.claudecode/mash"
cp -r "$TMPDIR_MASH/mash/.claudecode/mash/." "$TARGET_DIR/.claudecode/mash/"
ok ".claudecode/mash/"

# --- Step 4: Make scripts executable ---

chmod +x "$TARGET_DIR/.claudecode/mash/scripts/"*.sh
ok "Scripts marked executable"

# --- Step 5: Create scaffolding (only if missing) ---

created_scaffolding=false

for dir in .mash .mash/plan .mash/plan/features .mash/dev src tests; do
  if [ ! -d "$TARGET_DIR/$dir" ]; then
    mkdir -p "$TARGET_DIR/$dir"
    ok "Created $dir/"
    created_scaffolding=true
  fi
done

if [ ! -f "$TARGET_DIR/.mash/plan/architecture.md" ]; then
  cp "$TMPDIR_MASH/mash/.mash/plan/architecture.md" "$TARGET_DIR/.mash/plan/architecture.md"
  ok "Created .mash/plan/architecture.md"
  created_scaffolding=true
fi

if [ ! -f "$TARGET_DIR/.mash/plan/status.md" ]; then
  cp "$TMPDIR_MASH/mash/.mash/plan/status.md" "$TARGET_DIR/.mash/plan/status.md"
  ok "Created .mash/plan/status.md"
  created_scaffolding=true
fi

# Add .gitkeep to empty dirs
for dir in .mash/plan/features .mash/dev src tests; do
  if [ -z "$(ls -A "$TARGET_DIR/$dir" 2>/dev/null)" ]; then
    touch "$TARGET_DIR/$dir/.gitkeep"
  fi
done

if [ "$created_scaffolding" = false ]; then
  ok "Scaffolding already exists — skipped"
fi

# --- Step 6: Append MASH section to CLAUDE.md ---

CLAUDE_MD="$TARGET_DIR/CLAUDE.md"

if [ -f "$CLAUDE_MD" ] && grep -qF "$MARKER" "$CLAUDE_MD"; then
  ok "CLAUDE.md already has MASH section — skipped"
else
  cat >> "$CLAUDE_MD" <<'CLAUDE_EOF'

<!-- MASH -->
# MASH — Markdown Agile Sub-agent Hybrid

This project uses the MASH framework for planning and implementation.

## Conventions

- **`.mash/plan/`** is the source of truth for all specs, features, and architecture decisions.
- **`src/`** contains application source code.
- **`tests/`** contains test files.
- Feature files live in `.mash/plan/features/` with YAML frontmatter tracking status.
- The MASH skill (`.claudecode/mash/SKILL.md`) manages planning and delegates implementation to isolated sub-agents.

## Workflow

1. `mash init` — iteratively define your project (architecture + project).
2. `mash plan` — interactively create features with clarifying questions.
3. `mash dev <feature-id>` or `mash dev-all` — implement and test features via sub-agents.
4. MASH never writes code directly — it spawns sub-agents.
CLAUDE_EOF
  ok "Appended MASH section to CLAUDE.md"
fi

# --- Step 7: Append gitignore entries ---

GITIGNORE="$TARGET_DIR/.gitignore"

mash_gitignore_entries=(
  ".mash/plan/features/*.wip.md"
  ".mash/dev/"
)

if [ ! -f "$GITIGNORE" ]; then
  touch "$GITIGNORE"
fi

added_gitignore=false
for entry in "${mash_gitignore_entries[@]}"; do
  if ! grep -qxF "$entry" "$GITIGNORE"; then
    echo "$entry" >> "$GITIGNORE"
    added_gitignore=true
  fi
done

if [ "$added_gitignore" = true ]; then
  ok "Added MASH entries to .gitignore"
else
  ok ".gitignore already has MASH entries — skipped"
fi

# --- Step 8: Done ---

printf '\n\033[1;32mMASH installed successfully.\033[0m\n'
printf 'Run \033[1mmash\033[0m in Claude Code to get started.\n\n'
