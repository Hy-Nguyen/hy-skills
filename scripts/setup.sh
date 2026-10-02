#!/usr/bin/env bash
# One-time setup on a new machine: enable the repo's git hooks and link everything.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
git -C "$REPO" config core.hooksPath .githooks
"$REPO/scripts/sync.sh"
