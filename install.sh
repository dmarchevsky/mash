#!/usr/bin/env bash
set -euo pipefail

# MASH — Markdown Agile Sub-agent Hybrid
# Install script: curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh | bash
# Flags: --force to skip version check

MASH_REPO="https://github.com/dmarchevsky/mash.git"
MASH_TARBALL="https://github.com/dmarchevsky/mash/archive/refs/heads/main.tar.gz"
MARKER_START="<!-- MASH -->"
MARKER_END="<!-- /MASH -->"

TARGET_DIR="$PWD"
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
  esac
done

# --- Helpers ---

info()  { printf '  \033[1;34m→\033[0m %s\n' "$1"; }
ok()    { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
warn()  { printf '  \033[1;33m!\033[0m %s\n' "$1"; }
die()   { printf '  \033[1;31m✗\033[0m %s\n' "$1" >&2; exit 1; }

# --- Step 1: Validate ---

printf '\n\033[1mMASH Installer\033[0m\n\n'

[ -d "$TARGET_DIR/.git" ] || die "Not a git repo: $TARGET_DIR"

# --- Step 2: Download to temp dir ---

TMPDIR_MASH="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_MASH"' EXIT

MASH_SRC=""

# Try tarball first (faster, no git dependency)
if command -v curl &>/dev/null; then
  info "Downloading MASH framework..."
  if curl -sL "$MASH_TARBALL" | tar xz -C "$TMPDIR_MASH" 2>/dev/null; then
    MASH_SRC="$TMPDIR_MASH/mash-main"
  fi
fi

# Fall back to git clone
if [ -z "$MASH_SRC" ]; then
  info "Cloning MASH framework..."
  git clone --depth 1 --quiet "$MASH_REPO" "$TMPDIR_MASH/mash" || die "Failed to download MASH. Check your internet connection."
  MASH_SRC="$TMPDIR_MASH/mash"
fi

# --- Step 3: Version check ---

NEW_VERSION="unknown"
if [ -f "$MASH_SRC/VERSION" ]; then
  NEW_VERSION="$(cat "$MASH_SRC/VERSION" | tr -d '[:space:]')"
fi

INSTALLED_VERSION=""
if [ -f "$TARGET_DIR/.claude/mash/VERSION" ]; then
  INSTALLED_VERSION="$(cat "$TARGET_DIR/.claude/mash/VERSION" | tr -d '[:space:]')"
fi

if [ -n "$INSTALLED_VERSION" ]; then
  if [ "$INSTALLED_VERSION" = "$NEW_VERSION" ] && [ "$FORCE" = false ]; then
    ok "Already up to date (v$NEW_VERSION)"
    printf '\n'
    exit 0
  fi
  if [ "$INSTALLED_VERSION" != "$NEW_VERSION" ]; then
    info "Updating from v$INSTALLED_VERSION to v$NEW_VERSION"
    # Check for migration notes
    INSTALLED_MINOR="${INSTALLED_VERSION%.*}"
    NEW_MINOR="${NEW_VERSION%.*}"
    if [ "$INSTALLED_MINOR" != "$NEW_MINOR" ] && [ -d "$MASH_SRC/migrations" ]; then
      for migration in "$MASH_SRC/migrations/"*.md; do
        [ -f "$migration" ] && warn "Migration notes available: $(basename "$migration")"
      done
    fi
  fi
else
  info "Installing MASH v$NEW_VERSION"
fi

# --- Step 4: Copy framework files (always overwrite) ---

info "Installing framework files..."

mkdir -p "$TARGET_DIR/.claude/mash"
cp -r "$MASH_SRC/.claude/mash/." "$TARGET_DIR/.claude/mash/"
ok ".claude/mash/"

mkdir -p "$TARGET_DIR/.claude/commands"
cp "$MASH_SRC/.claude/commands/mash.md" "$TARGET_DIR/.claude/commands/mash.md"
ok ".claude/commands/mash.md"

# Copy version file
if [ -f "$MASH_SRC/VERSION" ]; then
  cp "$MASH_SRC/VERSION" "$TARGET_DIR/.claude/mash/VERSION"
  ok "VERSION (v$NEW_VERSION)"
fi

# --- Step 5: Create scaffolding (only if missing) ---

created_scaffolding=false

for dir in .mash .mash/plan .mash/plan/features .mash/dev src tests; do
  if [ ! -d "$TARGET_DIR/$dir" ]; then
    mkdir -p "$TARGET_DIR/$dir"
    ok "Created $dir/"
    created_scaffolding=true
  fi
done

# Add .gitkeep to empty dirs
for dir in .mash/plan/features .mash/dev src tests; do
  if [ -z "$(ls -A "$TARGET_DIR/$dir" 2>/dev/null)" ]; then
    touch "$TARGET_DIR/$dir/.gitkeep"
  fi
done

if [ "$created_scaffolding" = false ]; then
  ok "Scaffolding already exists — skipped"
fi

# --- Step 6: CLAUDE.md section (insert or replace) ---

CLAUDE_MD="$TARGET_DIR/CLAUDE.md"

MASH_SECTION="$(cat <<'CLAUDE_EOF'
<!-- MASH -->
# MASH — Markdown Agile Sub-agent Hybrid

This project uses the MASH framework for planning and implementation.

## Conventions

- **`.mash/plan/`** is the source of truth for all specs, features, and architecture decisions.
- **`src/`** contains application source code.
- **`tests/`** contains test files.
- Feature specs live in `.mash/plan/features/` with YAML frontmatter tracking status.
- Working copies for implementation live in `.mash/dev/`.
- `.mash/plan/progress.md` is the main status tracker.
- The MASH skill (`.claude/mash/SKILL.md`) manages planning and delegates implementation to isolated sub-agents via the Agent tool.

## Workflow

1. `mash init` — iteratively define your project (architecture + project).
2. `mash plan` — interactively create features with clarifying questions.
3. `mash dev [feature-ids]` — implement and test features via sub-agents (dev-persona then qa-persona).
4. `mash update` — check for and install framework updates.
5. `mash status` — show current progress.
6. MASH never writes code directly — it spawns sub-agents.
<!-- /MASH -->
CLAUDE_EOF
)"

if [ -f "$CLAUDE_MD" ] && grep -qF "$MARKER_START" "$CLAUDE_MD"; then
  if grep -qF "$MARKER_END" "$CLAUDE_MD"; then
    # Replace existing section between markers
    # Use awk to replace content between markers
    awk -v section="$MASH_SECTION" '
      /<!-- MASH -->/ { print section; skip=1; next }
      /<!-- \/MASH -->/ { skip=0; next }
      !skip { print }
    ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
    ok "CLAUDE.md MASH section updated"
  else
    # Old format without end marker — remove old section and append new
    # Remove everything from <!-- MASH --> to end of file, then append new section
    awk '/<!-- MASH -->/ { exit } { print }' "$CLAUDE_MD" > "$CLAUDE_MD.tmp"
    printf '%s\n' "$MASH_SECTION" >> "$CLAUDE_MD.tmp"
    mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
    ok "CLAUDE.md MASH section replaced (migrated to new format)"
  fi
else
  printf '\n%s\n' "$MASH_SECTION" >> "$CLAUDE_MD"
  ok "Appended MASH section to CLAUDE.md"
fi

# --- Step 7: Append gitignore entries ---

GITIGNORE="$TARGET_DIR/.gitignore"

mash_gitignore_entries=(
  ".mash/dev/"
  ".mash/worktrees/"
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

if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$NEW_VERSION" ]; then
  printf '\n\033[1;32mMASH updated to v%s.\033[0m\n\n' "$NEW_VERSION"
else
  printf '\n\033[1;32mMASH v%s installed successfully.\033[0m\n' "$NEW_VERSION"
  printf 'Run \033[1m/mash init\033[0m in Claude Code to get started.\n\n'
fi
