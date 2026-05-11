#!/usr/bin/env bash
# functional-emotions LLM gateway — Claude Code adapter.
#
# Contract (shared with all gateway scripts):
#   stdin  — prompt text
#   stdout — model response (raw text)
#   exit 0 — success
#   exit !0 — failure (caller falls back to heuristics or next tier)
#
# Discovery: scripts/lib.sh::eh_resolve_llm_gateway picks this up when
# `claude` is on PATH. Override the whole mechanism by setting
# EH_LLM_GATEWAY to your own script path that honors this contract.
#
# Recursion break: `claude --print` spawns a fresh Claude Code session,
# which would normally fire all of functional-emotions's SessionStart
# hooks and potentially loop. We pass CLAUDE_PLUGIN_OPTION_profile=off
# to silence the plugin in the sub-process — its own documented
# kill-switch, not a hack.
#
# Model: defers to EH_JUDGE_MODEL (set by the caller from
# eh_judge_model() in lib.sh), defaults to Haiku for cost/latency.
#
# State isolation: redirects CLAUDE_PROJECT_DIR to a stable temp dir so
# the sub-claude doesn't accumulate session-*.tsv files in the parent
# project's state directory.

set -u

prompt="$(cat 2>/dev/null || true)"
[[ -z "$prompt" ]] && exit 1
command -v claude >/dev/null 2>&1 || exit 1

model="${EH_JUDGE_MODEL:-claude-haiku-4-5-20251001}"

mkdir -p /tmp/fe-llm-gateway 2>/dev/null || true
# Best-effort cleanup of old gateway-session state (>7d).
find /tmp/fe-llm-gateway -mindepth 1 -mtime +7 -delete 2>/dev/null || true

CLAUDE_PLUGIN_OPTION_profile=off \
CLAUDE_PROJECT_DIR=/tmp/fe-llm-gateway \
  claude --print --model "$model" <<<"$prompt" 2>/dev/null
