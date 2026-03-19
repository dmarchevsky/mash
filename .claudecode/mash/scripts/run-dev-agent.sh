#!/usr/bin/env bash
set -euo pipefail

STORY_FILE="${1:?Usage: run-dev-agent.sh <story-file>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PERSONA_FILE="$SCRIPT_DIR/../references/dev-persona.md"
ARCH_FILE=".planning/architecture.md"

# Validate prerequisites
if ! command -v claude &>/dev/null; then
  echo "ERROR: 'claude' CLI not found in PATH" >&2
  exit 1
fi

if [[ ! -f "$STORY_FILE" ]]; then
  echo "ERROR: Story file not found: $STORY_FILE" >&2
  exit 1
fi

if [[ ! -f "$PERSONA_FILE" ]]; then
  echo "ERROR: Persona file not found: $PERSONA_FILE" >&2
  exit 1
fi

STORY_CONTENT="$(cat "$STORY_FILE")"
ARCH_CONTENT=""
if [[ -f "$ARCH_FILE" ]]; then
  ARCH_CONTENT="$(cat "$ARCH_FILE")"
fi

claude --system-prompt "$(cat "$PERSONA_FILE")" \
  --allowedTools "Bash,Read,Edit,Write,Glob,Grep" \
  --dangerously-skip-permissions \
  -p "Implement the requirements in this story.

## Story
$STORY_CONTENT

## Architecture
$ARCH_CONTENT"
