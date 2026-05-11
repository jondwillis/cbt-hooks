#!/usr/bin/env bash
# PostToolUse hook for the functional-emotions repo itself (not shipped
# with the plugin). Fires after Edit/Write/MultiEdit and emits a soft
# `additionalContext` reminder if the edited file is one of the
# source-of-truth files whose changes commonly drift from README.md /
# AGENTS.md.
#
# Wired up via .claude/settings.json -> PostToolUse -> Edit|Write|MultiEdit.
# Fails open: any error exits 0 with no output, so the plugin never
# blocks an edit.

set -u

path="$(jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$path" ]] && exit 0

# Match the source-of-truth set. Patterns are anchored at the end of
# the path so both absolute and relative paths work.
case "$path" in
  *"hooks/hooks.json" \
  | *".claude-plugin/plugin.json" \
  | *"scripts/lib.sh" \
  | */skills/*/SKILL.md)
    ;;
  *)
    exit 0
    ;;
esac

# Emit hookSpecificOutput.additionalContext for PostToolUse. The model
# sees this as feedback after the edit succeeds.
jq -nc --arg path "$path" '
{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: (
      "You edited a functional-emotions source-of-truth file (" + $path + ")." +
      " README.md and AGENTS.md may contain stale claims about hook tables," +
      " config keys/defaults, skill descriptions, or state-dir paths." +
      " Audit both before declaring this edit complete," +
      " or run /functional-emotions:docs-check for an automated drift scan."
    )
  }
}' 2>/dev/null || true
