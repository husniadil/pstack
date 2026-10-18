#!/usr/bin/env bash
# Fail when a Cursor tool, field, path, model, or product name is left in a file Claude Code loads.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

pattern='`Task`|\bTask (call|calls|tool|spawn|spawns|subagent|subagents)\b|AskQuestion|generalPurpose|readonly: (true|false)|environment: "(cloud|local)"|cloud_base_branch|file_attachments|run_in_background|is_background|\.mdc\b|~/\.cursor|\.cursor/|\bgrok-|claude-(opus|sonnet|haiku|fable)-[0-9]|setup-pstack|pstack-models|inherit-parent|docs/harness|SendToUser|update_state|api2\.cursor\.sh|cursor-team-kit|github\.com/cursor/plugins|\bCursor\b'

if grep -rnE "$pattern" pstack/skills pstack/agents pstack/docs pstack/README.md; then
  echo "Cursor names remain in the lines above. Port them per FORK.md." >&2
  exit 1
fi
echo "No Cursor names left."
