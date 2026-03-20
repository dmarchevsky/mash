#!/usr/bin/env bash
set -euo pipefail

FEATURE_FILE="${1:?Usage: run-qa-agent.sh <feature-file>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PERSONA_FILE="$SCRIPT_DIR/../references/qa-persona.md"
ARCH_FILE=".mash/plan/architecture.md"

# Validate prerequisites
if ! command -v claude &>/dev/null; then
  echo "ERROR: 'claude' CLI not found in PATH" >&2
  exit 1
fi

if [[ ! -f "$FEATURE_FILE" ]]; then
  echo "ERROR: Feature file not found: $FEATURE_FILE" >&2
  exit 1
fi

if [[ ! -f "$PERSONA_FILE" ]]; then
  echo "ERROR: Persona file not found: $PERSONA_FILE" >&2
  exit 1
fi

FEATURE_CONTENT="$(cat "$FEATURE_FILE")"
ARCH_CONTENT=""
if [[ -f "$ARCH_FILE" ]]; then
  ARCH_CONTENT="$(cat "$ARCH_FILE")"
fi

claude --system-prompt "$(cat "$PERSONA_FILE")" \
  --allowedTools "Bash,Read,Edit,Write,Glob,Grep" \
  --dangerously-skip-permissions \
  -p "Test the implementation for this feature. Write tests, run them, and append the result to the feature file at $FEATURE_FILE.

## Feature
$FEATURE_CONTENT

## Architecture
$ARCH_CONTENT"
