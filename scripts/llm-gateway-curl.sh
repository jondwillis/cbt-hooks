#!/usr/bin/env bash
# functional-emotions LLM gateway — direct Anthropic API adapter.
#
# Contract (shared with all gateway scripts):
#   stdin  — prompt text
#   stdout — model response (raw text)
#   exit 0 — success
#   exit !0 — failure (caller falls back to heuristics)
#
# Used as a fallback for headless / CI environments where the `claude`
# CLI isn't installed but ANTHROPIC_API_KEY is. Discovery:
# scripts/lib.sh::eh_resolve_llm_gateway picks this up only when claude
# isn't on PATH AND the API key is set — so a normal Claude Code dev
# session uses the CLI gateway by default and never hits this script.
#
# Override the whole mechanism via EH_LLM_GATEWAY=/path/to/your-script.

set -u

prompt="$(cat 2>/dev/null || true)"
[[ -z "$prompt" ]] && exit 1

[[ -n "${ANTHROPIC_API_KEY:-}" ]] || exit 1
command -v curl >/dev/null 2>&1 || exit 1
command -v jq   >/dev/null 2>&1 || exit 1

model="${EH_JUDGE_MODEL:-claude-haiku-4-5-20251001}"

payload="$(jq -nc --arg p "$prompt" --arg m "$model" '{
  model: $m,
  max_tokens: 500,
  messages: [{role: "user", content: $p}]
}' 2>/dev/null)" || exit 1

response="$(curl -s --max-time 60 -X POST "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$payload" 2>/dev/null || true)"

text="$(printf '%s' "$response" | jq -r '.content[0].text // empty' 2>/dev/null || true)"
[[ -n "$text" ]] || exit 1
printf '%s' "$text"
