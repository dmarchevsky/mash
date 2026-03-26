# Changelog

All notable changes to MASH will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.1.1] — 2026-03-26

### Fixed
- macOS compatibility: use explicit `tar -xz` flags for BSD tar
- macOS compatibility: replace `ls -A` empty dir check with portable `find`
- Remove useless `cat` in version reads (`tr < file` instead of `cat file | tr`)

## [0.1.0] — 2026-03-24

### Added
- Init persona with multi-turn interactive project definition
- Plan persona with iterative feature brainstorming and specification
- Dev persona for autonomous feature implementation via sub-agents
- QA persona for test-driven verification of acceptance criteria
- Git workflow settings: worktree branching or current branch, auto or manual commit
- Permission checking and auto-configuration for sub-agent autonomy
- Install script with per-project installation via `curl | bash`
- Version tracking and `mash update` command
