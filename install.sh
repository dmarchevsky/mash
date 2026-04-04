#!/usr/bin/env bash
set -euo pipefail

# MASH — Multi-Agent Software Harness
# Install script: bash <(curl -sL https://raw.githubusercontent.com/dmarchevsky/mash/main/install.sh)
# Flags: --force to skip version check
#        --claude   install Claude Code support only
#        --opencode install opencode support only

MASH_REPO="https://github.com/dmarchevsky/mash.git"
MASH_TARBALL="https://github.com/dmarchevsky/mash/archive/refs/heads/main.tar.gz"
MARKER_START="<!-- MASH -->"
MARKER_END="<!-- /MASH -->"

TARGET_DIR="$PWD"
CLAUDE_HOME="${HOME}/.claude"
OPENCODE_HOME="${HOME}/.config/opencode"
FORCE=false
FLAG_CLAUDE=false
FLAG_OPENCODE=false

for arg in "$@"; do
  case "$arg" in
    --force)    FORCE=true ;;
    --claude)   FLAG_CLAUDE=true ;;
    --opencode) FLAG_OPENCODE=true ;;
  esac
done

# --- Helpers ---

info()  { printf '  \033[1;34m→\033[0m %s\n' "$1"; }
ok()    { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
warn()  { printf '  \033[1;33m!\033[0m %s\n' "$1"; }
die()   { printf '  \033[1;31m✗\033[0m %s\n' "$1" >&2; exit 1; }

# --- Step 1: Validate ---

printf '\n\033[1mMASH Installer\033[0m\n\n'

# --- Step 2: Download to temp dir ---

TMPDIR_MASH="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_MASH"' EXIT

MASH_SRC=""

# Try tarball first (faster, no git dependency)
if command -v curl &>/dev/null; then
  info "Downloading MASH framework..."
  if curl -sL "$MASH_TARBALL" | tar -xz -C "$TMPDIR_MASH" 2>/dev/null; then
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
  NEW_VERSION="$(tr -d '[:space:]' < "$MASH_SRC/VERSION")"
fi

INSTALLED_VERSION=""
if [ -f "$CLAUDE_HOME/skills/mash/VERSION" ]; then
  INSTALLED_VERSION="$(tr -d '[:space:]' < "$CLAUDE_HOME/skills/mash/VERSION")"
elif [ -f "$OPENCODE_HOME/mash/VERSION" ]; then
  INSTALLED_VERSION="$(tr -d '[:space:]' < "$OPENCODE_HOME/mash/VERSION")"
elif [ -f "$OPENCODE_HOME/agents/mash/VERSION" ]; then
  INSTALLED_VERSION="$(tr -d '[:space:]' < "$OPENCODE_HOME/agents/mash/VERSION")"
elif [ -f "$OPENCODE_HOME/skills/mash/VERSION" ]; then
  INSTALLED_VERSION="$(tr -d '[:space:]' < "$OPENCODE_HOME/skills/mash/VERSION")"
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

# --- Step 3b: Detect AI clients ---

HAS_CLAUDE=false
HAS_OPENCODE=false
command -v claude   &>/dev/null && HAS_CLAUDE=true
command -v opencode &>/dev/null && HAS_OPENCODE=true

INSTALL_CLAUDE=false
INSTALL_OPENCODE=false

# Explicit flags take priority over auto-detection
if [ "$FLAG_CLAUDE" = true ] || [ "$FLAG_OPENCODE" = true ]; then
  [ "$FLAG_CLAUDE"   = true ] && INSTALL_CLAUDE=true
  [ "$FLAG_OPENCODE" = true ] && INSTALL_OPENCODE=true
elif [ "$HAS_CLAUDE" = true  ] && [ "$HAS_OPENCODE" = false ]; then
  INSTALL_CLAUDE=true
elif [ "$HAS_CLAUDE" = false ] && [ "$HAS_OPENCODE" = true  ]; then
  INSTALL_OPENCODE=true
elif [ "$HAS_CLAUDE" = true  ] && [ "$HAS_OPENCODE" = true  ]; then
  if [ -t 0 ]; then
    printf '\nBoth Claude Code and opencode are installed. Install MASH for:\n'
    printf '  1) Claude Code only\n'
    printf '  2) opencode only\n'
    printf '  3) Both\n'
    printf 'Choice [3]: '
    read -r CLIENT_CHOICE
    CLIENT_CHOICE="${CLIENT_CHOICE:-3}"
    case "$CLIENT_CHOICE" in
      1) INSTALL_CLAUDE=true ;;
      2) INSTALL_OPENCODE=true ;;
      *) INSTALL_CLAUDE=true; INSTALL_OPENCODE=true ;;
    esac
  else
    info "Both clients detected. Pass --claude or --opencode to install for one. Installing for both."
    INSTALL_CLAUDE=true
    INSTALL_OPENCODE=true
  fi
else
  die "Neither 'claude' nor 'opencode' found in PATH. Install one of them first."
fi

# --- Step 3c: Migrate from local to global installation ---

OLD_CLAUDE_SKILL="$TARGET_DIR/skills/mash"
OLD_OPENCODE_SKILL="$TARGET_DIR/.opencode/skills/mash"

if [ -d "$OLD_CLAUDE_SKILL" ] || [ -d "$OLD_OPENCODE_SKILL" ]; then
  warn "Migrating from local to global installation..."

  # Remove local skill directories
  [ -d "$TARGET_DIR/skills" ] && rm -rf "$TARGET_DIR/skills" && ok "Removed skills/"
  [ -d "$TARGET_DIR/.opencode/skills" ] && rm -rf "$TARGET_DIR/.opencode/skills" && ok "Removed .opencode/skills/"
  [ -d "$TARGET_DIR/.opencode/commands" ] && rm -rf "$TARGET_DIR/.opencode/commands" && ok "Removed .opencode/commands/"
  [ -f "$TARGET_DIR/.claude/commands/mash.md" ] && rm -f "$TARGET_DIR/.claude/commands/mash.md" && ok "Removed .claude/commands/mash.md"

  # Remove global command if installed by a previous version
  [ -f "$CLAUDE_HOME/commands/mash.md" ] && rm -f "$CLAUDE_HOME/commands/mash.md" && ok "Removed ~/.claude/commands/mash.md"

  # Remove old gitignore entries
  GITIGNORE="$TARGET_DIR/.gitignore"
  if [ -f "$GITIGNORE" ]; then
    sed -i '/^skills\/mash\/$/d; /^\.opencode\/$/d' "$GITIGNORE" 2>/dev/null || true
    ok "Cleaned .gitignore"
  fi

  # Remove skills.paths from opencode.json if present
  if [ -f "$TARGET_DIR/opencode.json" ]; then
    if command -v node &>/dev/null; then
      node -e "
        const f='$TARGET_DIR/opencode.json';
        const j=JSON.parse(require('fs').readFileSync(f,'utf8'));
        delete j.skills;
        require('fs').writeFileSync(f,JSON.stringify(j,null,2)+'\n');
      " 2>/dev/null && ok "Removed skills path from opencode.json" || true
    fi
  fi

  ok "Local install cleaned up — continuing with global install"
fi

# --- Step 4: Install framework files globally ---

info "Installing framework files..."

if [ "$INSTALL_CLAUDE" = true ]; then
  mkdir -p "$CLAUDE_HOME/skills/mash"

  # Install SKILL.md with rewritten paths (skills/mash/references/ → absolute)
  sed "s|skills/mash/references/|$CLAUDE_HOME/skills/mash/references/|g; s|skills/mash/VERSION|$CLAUDE_HOME/skills/mash/VERSION|g" \
    "$MASH_SRC/skills/mash/SKILL.md" > "$CLAUDE_HOME/skills/mash/SKILL.md"
  ok "$CLAUDE_HOME/skills/mash/SKILL.md"

  # Install references with rewritten paths
  cp -r "$MASH_SRC/skills/mash/references" "$CLAUDE_HOME/skills/mash/"
  for f in "$CLAUDE_HOME/skills/mash/references/"*.md; do
    sed -i "s|skills/mash/references/|$CLAUDE_HOME/skills/mash/references/|g" "$f"
  done
  ok "$CLAUDE_HOME/skills/mash/references/"

  if [ -f "$MASH_SRC/VERSION" ]; then
    cp "$MASH_SRC/VERSION" "$CLAUDE_HOME/skills/mash/VERSION"
    ok "VERSION (v$NEW_VERSION)"
  fi
fi

if [ "$INSTALL_OPENCODE" = true ]; then
  mkdir -p "$OPENCODE_HOME/agents" "$OPENCODE_HOME/mash"

  # Migrate: remove legacy installs if present
  if [ -d "$OPENCODE_HOME/agents/mash" ]; then
    rm -rf "$OPENCODE_HOME/agents/mash"
    ok "Removed legacy $OPENCODE_HOME/agents/mash/"
  fi
  if [ -d "$OPENCODE_HOME/skills/mash" ]; then
    rm -rf "$OPENCODE_HOME/skills/mash"
    ok "Removed legacy $OPENCODE_HOME/skills/mash/"
  fi

  # Assemble agent file: frontmatter + opencode preamble + main SKILL.md body with rewritten paths
  head -5 "$MASH_SRC/opencode-agents/mash/AGENT.md" > "$OPENCODE_HOME/agents/mash.md"
  cat "$MASH_SRC/opencode-agents/mash/PREAMBLE.md" >> "$OPENCODE_HOME/agents/mash.md"
  tail -n +5 "$MASH_SRC/skills/mash/SKILL.md" \
    | sed "s|skills/mash/references/|$OPENCODE_HOME/mash/references/|g; s|skills/mash/VERSION|$OPENCODE_HOME/mash/VERSION|g" \
    >> "$OPENCODE_HOME/agents/mash.md"
  ok "$OPENCODE_HOME/agents/mash.md"

  # Install references with rewritten paths (in $OPENCODE_HOME/mash/ to avoid @mash collision)
  cp -r "$MASH_SRC/skills/mash/references" "$OPENCODE_HOME/mash/"
  for f in "$OPENCODE_HOME/mash/references/"*.md; do
    sed -i "s|skills/mash/references/|$OPENCODE_HOME/mash/references/|g" "$f"
  done
  ok "$OPENCODE_HOME/mash/references/"

  if [ -f "$MASH_SRC/VERSION" ]; then
    cp "$MASH_SRC/VERSION" "$OPENCODE_HOME/mash/VERSION"
    ok "VERSION (v$NEW_VERSION)"
  fi
fi

# --- Step 5: Create scaffolding (only if missing) ---

created_scaffolding=false

for dir in .mash .mash/plan .mash/plan/features .mash/dev; do
  if [ ! -d "$TARGET_DIR/$dir" ]; then
    mkdir -p "$TARGET_DIR/$dir"
    ok "Created $dir/"
    created_scaffolding=true
  fi
done

# Add .gitkeep to empty dirs
for dir in .mash/plan/features .mash/dev; do
  if ! find "$TARGET_DIR/$dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .; then
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
# MASH — Multi-Agent Software Harness

This project uses the MASH framework for planning and implementation.

## Conventions

- **`.mash/plan/`** is the source of truth for all specs, features, and architecture decisions.
- **`src/`** contains application source code.
- **`tests/`** contains test files.
- Feature specs live in `.mash/plan/features/` with YAML frontmatter tracking status.
- Working copies for implementation live in `.mash/dev/`.
- `.mash/plan/progress.md` is the main status tracker.
- The MASH skill (`~/.claude/skills/mash/SKILL.md`) manages planning and delegates implementation to isolated sub-agents via the Agent tool.

## Invocation

When the user says `mash [command]` (e.g. `mash init`, `mash dev 1,3`), read `~/.claude/skills/mash/SKILL.md` and follow its instructions exactly, passing through any arguments.

## Workflow

1. `mash init` — iteratively define your project (architecture + project).
2. `mash plan` — interactively create features with clarifying questions.
3. `mash dev [feature-ids]` — implement and test features via sub-agents (dev-persona then qa-persona).
4. `mash fix [description|id]` — debug defects collaboratively, then patch and verify.
5. `mash config` — view or change git settings and sub-agent permissions.
6. `mash status` — show current progress.
7. `mash update` — check for and install framework updates.
8. MASH never writes code directly — it spawns sub-agents.
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

mash_gitignore_entries=(".mash/dev/" ".mash/worktrees/" ".claude/")

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

# --- Step 8: Project-level opencode.json (permissions only) ---

if [ "$INSTALL_OPENCODE" = true ]; then
  OPENCODE_JSON="$TARGET_DIR/opencode.json"
  if [ ! -f "$OPENCODE_JSON" ]; then
    cp "$MASH_SRC/opencode.json" "$OPENCODE_JSON"
    ok "opencode.json"
  else
    ok "opencode.json already exists — skipped"
  fi
fi

# --- Step 9: Done ---

if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$NEW_VERSION" ]; then
  printf '\n\033[1;32mMASH updated to v%s.\033[0m\n\n' "$NEW_VERSION"
else
  printf '\n\033[1;32mMASH v%s installed successfully.\033[0m\n' "$NEW_VERSION"
  if [ "$INSTALL_CLAUDE" = true ] && [ "$INSTALL_OPENCODE" = true ]; then
    printf 'Run \033[1mmash init\033[0m in Claude Code or ask MASH to initialize your project in opencode.\n\n'
  elif [ "$INSTALL_OPENCODE" = true ]; then
    printf 'Ask MASH to initialize your project in opencode (e.g. "mash init").\n\n'
  else
    printf 'Run \033[1mmash init\033[0m in Claude Code to get started.\n\n'
  fi
fi
