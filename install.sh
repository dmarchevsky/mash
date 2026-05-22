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

CLAUDE_VERSION=""
OPENCODE_VERSION=""
if [ -f "$CLAUDE_HOME/skills/mash/VERSION" ]; then
  CLAUDE_VERSION="$(tr -d '[:space:]' < "$CLAUDE_HOME/skills/mash/VERSION")"
elif [ -f "$CLAUDE_HOME/mash/VERSION" ]; then
  CLAUDE_VERSION="$(tr -d '[:space:]' < "$CLAUDE_HOME/mash/VERSION")"
fi
if [ -f "$OPENCODE_HOME/mash/VERSION" ]; then
  OPENCODE_VERSION="$(tr -d '[:space:]' < "$OPENCODE_HOME/mash/VERSION")"
fi
INSTALLED_VERSION="${CLAUDE_VERSION:-$OPENCODE_VERSION}"

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

# --- Step 3c: Version check (after platform detection) ---

# Only skip if ALL selected platforms are already at the target version
ALL_CURRENT=true
if [ "$INSTALL_CLAUDE" = true ] && [ "$CLAUDE_VERSION" != "$NEW_VERSION" ]; then
  ALL_CURRENT=false
fi
if [ "$INSTALL_OPENCODE" = true ] && [ "$OPENCODE_VERSION" != "$NEW_VERSION" ]; then
  ALL_CURRENT=false
fi

if [ "$ALL_CURRENT" = true ] && [ "$FORCE" = false ]; then
  ok "Already up to date (v$NEW_VERSION)"
  printf '\n'
  exit 0
fi

if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$NEW_VERSION" ]; then
  info "Updating from v$INSTALLED_VERSION to v$NEW_VERSION"
elif [ -z "$INSTALLED_VERSION" ]; then
  info "Installing MASH v$NEW_VERSION"
fi

# --- Step 4: Install framework files globally ---

info "Installing framework files..."

if [ "$INSTALL_CLAUDE" = true ]; then
  CLAUDE_SKILL_DIR="$CLAUDE_HOME/skills/mash"
  mkdir -p "$CLAUDE_SKILL_DIR"

  # Clean up legacy install location if present
  if [ -d "$CLAUDE_HOME/mash" ] && [ "$CLAUDE_HOME/mash" != "$CLAUDE_SKILL_DIR" ]; then
    rm -rf "$CLAUDE_HOME/mash"
    info "Removed legacy install at $CLAUDE_HOME/mash"
  fi
  # Remove legacy command shim (native skill discovery replaces it)
  rm -f "$CLAUDE_HOME/commands/mash.md"

  # Install SKILL.md directly — ${CLAUDE_SKILL_DIR} resolves natively
  cp "$MASH_SRC/skills/mash/SKILL.md" "$CLAUDE_SKILL_DIR/SKILL.md"
  ok "$CLAUDE_SKILL_DIR/SKILL.md"

  # Install commands, shared, and references (no sed rewriting needed)
  for subdir in commands shared references; do
    if [ -d "$MASH_SRC/skills/mash/$subdir" ]; then
      rm -rf "$CLAUDE_SKILL_DIR/$subdir"
      cp -r "$MASH_SRC/skills/mash/$subdir" "$CLAUDE_SKILL_DIR/"
      ok "$CLAUDE_SKILL_DIR/$subdir/"
    fi
  done

  if [ -f "$MASH_SRC/VERSION" ]; then
    cp "$MASH_SRC/VERSION" "$CLAUDE_SKILL_DIR/VERSION"
    ok "VERSION (v$NEW_VERSION)"
  fi

  # Update global Claude Code settings to pre-approve reads from skill dir
  GLOBAL_CC_SETTINGS="$CLAUDE_HOME/settings.json"
  MASH_READ_PATTERN="Read($CLAUDE_SKILL_DIR/**)"
  if [ ! -f "$GLOBAL_CC_SETTINGS" ]; then
    printf '{\n  "permissions": {\n    "allow": [\n      "%s"\n    ]\n  }\n}\n' "$MASH_READ_PATTERN" > "$GLOBAL_CC_SETTINGS"
    ok "$GLOBAL_CC_SETTINGS"
  else
    # Remove any legacy permission patterns (both single * and double **)
    if grep -qE "Read\($CLAUDE_HOME/mash/\*{1,2}\)" "$GLOBAL_CC_SETTINGS" 2>/dev/null; then
      # Use awk to safely remove the line and fix trailing commas in the JSON array
      awk -v pat="$CLAUDE_HOME/mash/" '
        $0 ~ pat { next }
        { print }
      ' "$GLOBAL_CC_SETTINGS" > "$GLOBAL_CC_SETTINGS.tmp" && mv "$GLOBAL_CC_SETTINGS.tmp" "$GLOBAL_CC_SETTINGS"
      # Clean up any trailing commas before ] that the removal may have created
      sed -i -E ':a; N; $!ba; s/,([[:space:]]*\])/\1/g' "$GLOBAL_CC_SETTINGS"
      info "Removed legacy Read permission for $CLAUDE_HOME/mash/"
    fi
    if grep -qF "$MASH_READ_PATTERN" "$GLOBAL_CC_SETTINGS" 2>/dev/null; then
      ok "$GLOBAL_CC_SETTINGS already has Read permission — skipped"
    elif grep -q '"allow"' "$GLOBAL_CC_SETTINGS" 2>/dev/null; then
      sed -i 's|"allow": \[|"allow": [\n      "'"$MASH_READ_PATTERN"'",|' "$GLOBAL_CC_SETTINGS"
      # Clean up any trailing commas before ] (e.g. if array was empty after legacy removal)
      sed -i -E ':a; N; $!ba; s/,([[:space:]]*\])/\1/g' "$GLOBAL_CC_SETTINGS"
      ok "$GLOBAL_CC_SETTINGS (Read permission for $CLAUDE_SKILL_DIR/**)"
    elif grep -q '"permissions"' "$GLOBAL_CC_SETTINGS" 2>/dev/null; then
      sed -i 's|"permissions": {|"permissions": {\n    "allow": [\n      "'"$MASH_READ_PATTERN"'"\n    ],|' "$GLOBAL_CC_SETTINGS"
      ok "$GLOBAL_CC_SETTINGS (Read permission for $CLAUDE_SKILL_DIR/**)"
    else
      sed -i '$ s|}|,\n  "permissions": {\n    "allow": [\n      "'"$MASH_READ_PATTERN"'"\n    ]\n  }\n}|' "$GLOBAL_CC_SETTINGS"
      ok "$GLOBAL_CC_SETTINGS (Read permission for $CLAUDE_SKILL_DIR/**)"
    fi
  fi
fi

if [ "$INSTALL_OPENCODE" = true ]; then
  mkdir -p "$OPENCODE_HOME/commands" "$OPENCODE_HOME/mash"

  # Install SKILL.md with ${CLAUDE_SKILL_DIR} rewritten to absolute paths for OpenCode
  sed "s|\${CLAUDE_SKILL_DIR}/|$OPENCODE_HOME/mash/|g; s|\${CLAUDE_SKILL_DIR}|$OPENCODE_HOME/mash|g" \
    "$MASH_SRC/skills/mash/SKILL.md" > "$OPENCODE_HOME/mash/SKILL.md"
  ok "$OPENCODE_HOME/mash/SKILL.md"

  # Install commands, shared, and references with rewritten paths
  for subdir in commands shared references; do
    if [ -d "$MASH_SRC/skills/mash/$subdir" ]; then
      rm -rf "$OPENCODE_HOME/mash/$subdir"
      cp -r "$MASH_SRC/skills/mash/$subdir" "$OPENCODE_HOME/mash/"
      find "$OPENCODE_HOME/mash/$subdir" -name '*.md' -exec \
        sed -i "s|\${CLAUDE_SKILL_DIR}/|$OPENCODE_HOME/mash/|g; s|\${CLAUDE_SKILL_DIR}|$OPENCODE_HOME/mash|g" {} +
      ok "$OPENCODE_HOME/mash/$subdir/"
    fi
  done

  if [ -f "$MASH_SRC/VERSION" ]; then
    cp "$MASH_SRC/VERSION" "$OPENCODE_HOME/mash/VERSION"
    ok "VERSION (v$NEW_VERSION)"
  fi

  # Install /mash global command (preamble + read instruction)
  {
    printf -- '---\ndescription: "MASH — Multi-Agent Software Harness. Commands: init, plan, dev [ids], fix [id|desc], status, update, config"\n---\n\n'
    cat "$MASH_SRC/opencode-command/mash/PREAMBLE.md"
    printf '\nRead `%s/mash/SKILL.md` and follow its instructions exactly. $ARGUMENTS\n' "$OPENCODE_HOME"
  } > "$OPENCODE_HOME/commands/mash.md"
  ok "$OPENCODE_HOME/commands/mash.md"

  # Write global opencode config with external_directory permission (pre-approves ~/.config/opencode/mash/ reads)
  GLOBAL_OC_CONFIG="$OPENCODE_HOME/config.json"
  MASH_DIR="$OPENCODE_HOME/mash"
  if [ ! -f "$GLOBAL_OC_CONFIG" ]; then
    printf '{\n  "$schema": "https://opencode.ai/config.json",\n  "permission": {\n    "external_directory": {\n      "%s/*": "allow"\n    }\n  }\n}\n' "$MASH_DIR" > "$GLOBAL_OC_CONFIG"
    ok "$GLOBAL_OC_CONFIG"
  elif grep -qF "$MASH_DIR" "$GLOBAL_OC_CONFIG" 2>/dev/null; then
    ok "$GLOBAL_OC_CONFIG already has external_directory — skipped"
  elif grep -q '"external_directory"' "$GLOBAL_OC_CONFIG" 2>/dev/null; then
    # Inject into existing external_directory object
    sed -i 's|"external_directory": {|"external_directory": {\n      "'"$MASH_DIR"'/*": "allow",|' "$GLOBAL_OC_CONFIG"
    ok "$GLOBAL_OC_CONFIG (external_directory: $MASH_DIR/*)"
  elif grep -q '"permission"' "$GLOBAL_OC_CONFIG" 2>/dev/null; then
    # Inject external_directory into existing permission block
    sed -i 's|"permission": {|"permission": {\n    "external_directory": {\n      "'"$MASH_DIR"'/*": "allow"\n    },|' "$GLOBAL_OC_CONFIG"
    ok "$GLOBAL_OC_CONFIG (external_directory: $MASH_DIR/*)"
  else
    # No permission section — insert before last closing brace
    sed -i '$ s|}|,\n  "permission": {\n    "external_directory": {\n      "'"$MASH_DIR"'/*": "allow"\n    }\n  }\n}|' "$GLOBAL_OC_CONFIG"
    ok "$GLOBAL_OC_CONFIG (external_directory: $MASH_DIR/*)"
  fi
fi

# --- Step 5: CLAUDE.md section (insert or replace) ---

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
- The MASH command (`/mash`) manages planning and delegates implementation to isolated sub-agents via the Agent tool.

## Invocation

Use `/mash [command]` (e.g. `/mash init`, `/mash dev 1,3`).

## Workflow

1. `/mash init` — iteratively define your project (architecture + project).
2. `/mash plan` — interactively create features with clarifying questions.
3. `/mash dev [feature-ids]` — implement and test features via sub-agents (dev-persona then qa-persona).
4. `/mash fix [description|id]` — debug defects collaboratively, then patch and verify.
5. `/mash config` — view or change git settings and sub-agent permissions.
6. `/mash status` — show current progress.
7. `/mash update` — check for and install framework updates.
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

# --- Step 6: Append gitignore entries ---

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

# --- Step 7: Project-level opencode.json (permissions only) ---

if [ "$INSTALL_OPENCODE" = true ]; then
  OPENCODE_JSON="$TARGET_DIR/opencode.json"
  if [ ! -f "$OPENCODE_JSON" ]; then
    cp "$MASH_SRC/opencode.json" "$OPENCODE_JSON"
    ok "opencode.json"
  else
    ok "opencode.json already exists — skipped"
  fi
fi

# --- Step 8: Done ---

if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$NEW_VERSION" ]; then
  printf '\n\033[1;32mMASH updated to v%s.\033[0m\n\n' "$NEW_VERSION"
else
  printf '\n\033[1;32mMASH v%s installed successfully.\033[0m\n' "$NEW_VERSION"
  printf 'Run \033[1m/mash init\033[0m to get started.\n\n'
fi
