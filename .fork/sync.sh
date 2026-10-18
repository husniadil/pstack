#!/usr/bin/env bash
# Merge upstream/main into main without committing, and settle the paths this fork removes or owns.
# Exit 0: merge staged with no conflicts left. Exit 2: conflicts left to port. Exit 3: nothing new.
# Rename detection is off: this fork never moves files, and a detected rename would carry upstream
# changes, or whole harness folders, into fork-owned paths.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is not clean. Commit or stash first." >&2
  exit 1
fi

git checkout --quiet main
git fetch --quiet origin
git fetch --quiet upstream
git merge --ff-only --quiet origin/main

if git merge-base --is-ancestor upstream/main HEAD; then
  echo "main already contains upstream/main $(git rev-parse --short upstream/main)."
  exit 3
fi

git merge --no-commit --no-ff -X no-renames upstream/main >/dev/null 2>&1 || true

dropped() {
  case "$1" in
    pstack/automations/* | pstack/skills/setup-pstack/* | pstack/docs/harness/* | pstack/.cursor-plugin/*) return 0 ;;
    pstack/* | .fork/* | FORK.md | .gitignore | .claude-plugin/marketplace.json) return 1 ;;
    *) return 0 ;;
  esac
}

git ls-files | sort -u | while IFS= read -r f; do
  if dropped "$f"; then git rm -qf --ignore-unmatch -- "$f"; fi
done
git checkout HEAD -- .claude-plugin/marketplace.json pstack/.claude-plugin/plugin.json

echo "Merging upstream/main $(git rev-parse --short upstream/main)."
echo
echo "pstack files upstream changed (port each one):"
git diff --cached --name-only HEAD -- pstack | sed 's/^/  /'
echo

conflicts=$(git diff --name-only --diff-filter=U)
if [ -n "$conflicts" ]; then
  echo "Conflicts left:"
  echo "$conflicts" | sed 's/^/  /'
  exit 2
fi
echo "No conflicts left."
