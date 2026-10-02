#!/usr/bin/env bash
# Symlink every skill and subagent in this repo into the directories agents read from.
# Because they're symlinks, edits in the repo are live immediately; re-run only when
# skills/agents are added or removed (the git hooks in .githooks do this for you).
#
#   skills/<name>/   -> ~/.agents/skills/<name>   (Codex, Cursor, and other agents)
#                    -> ~/.claude/skills/<name>   (Claude Code)
#   agents/<name>.md -> ~/.claude/agents/<name>.md (Claude Code subagents)
#
# Existing non-symlink files in the way are moved to ~/.hy-skills-backup/<timestamp>/.
# Symlinks that point into this repo but whose source was deleted are removed.
#
# Usage: scripts/sync.sh [--dry-run]

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP="$HOME/.hy-skills-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

SKILL_TARGETS=("$HOME/.agents/skills" "$HOME/.claude/skills")
AGENT_TARGETS=("$HOME/.claude/agents")

run() {
  if $DRY_RUN; then echo "  [dry-run] $*"; else "$@"; fi
}

# link <source> <dest>
link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "  backup  $dest -> $BACKUP/"
    run mkdir -p "$BACKUP/$(basename "$(dirname "$dest")")"
    run mv "$dest" "$BACKUP/$(basename "$(dirname "$dest")")/"
  fi
  echo "  link    $dest"
  run ln -s "$src" "$dest"
}

# prune <dir>: remove symlinks into this repo whose source no longer exists
prune() {
  local dir="$1" entry target
  for entry in "$dir"/*; do
    [[ -L "$entry" ]] || continue
    target="$(readlink "$entry")"
    if [[ "$target" == "$REPO"/* && ! -e "$target" ]]; then
      echo "  prune   $entry"
      run rm "$entry"
    fi
  done
}

for target in "${SKILL_TARGETS[@]}"; do
  echo "skills -> $target"
  run mkdir -p "$target"
  for skill in "$REPO"/skills/*/; do
    skill="${skill%/}"
    [[ -f "$skill/SKILL.md" ]] || continue
    link "$skill" "$target/$(basename "$skill")"
  done
  prune "$target"
done

for target in "${AGENT_TARGETS[@]}"; do
  echo "agents -> $target"
  run mkdir -p "$target"
  for agent in "$REPO"/agents/*.md; do
    [[ -f "$agent" ]] || continue
    link "$agent" "$target/$(basename "$agent")"
  done
  prune "$target"
done

echo "done"
