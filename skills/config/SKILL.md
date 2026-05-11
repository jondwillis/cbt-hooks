---
name: config
description: Show the active functional-emotions config as a table — current resolved values, where each value came from (default / profile-derived / explicit override), and the valid options for each field. Use when you want to know what the plugin will actually do this session, or when the `/plugin config functional-emotions` UI didn't show enough context.
disable-model-invocation: false
allowed-tools: Bash
---

Print the active config the way `/plugin config functional-emotions` cannot:
with the **resolved current value** of each field, the **source** of that
value (default / profile / override), and the **valid options**.

Run this single bash block, then render its output as a markdown table:

```bash
. "${CLAUDE_PLUGIN_ROOT:?CLAUDE_PLUGIN_ROOT unset — am I running outside Claude Code?}/scripts/lib.sh"

# Returns "override" if the user set CLAUDE_PLUGIN_OPTION_<key> (or legacy
# CLAUDE_PLUGIN_CONFIG_<key>); otherwise returns the supplied fallback,
# which is "profile" for fields with a profile-derived default and
# "default" for the independent tuning knobs.
eh_value_source() {
  local key="$1" fallback="$2" v
  v="$(printenv "CLAUDE_PLUGIN_OPTION_${key}" 2>/dev/null || true)"
  [[ -z "$v" ]] && v="$(printenv "CLAUDE_PLUGIN_CONFIG_${key}" 2>/dev/null || true)"
  if [[ -n "$v" ]]; then printf 'override'; else printf '%s' "$fallback"; fi
}

# field <TAB> current <TAB> source <TAB> options <TAB> hard default
printf 'profile\t%s\t%s\tbalanced | quiet | off\tbalanced\n' \
  "$(eh_profile)" "$(eh_value_source profile default)"
printf 'mode\t%s\t%s\tloud | gentle | silent\t(profile)\n' \
  "$(eh_mode)" "$(eh_value_source mode profile)"
printf 'failure_spiral_threshold\t%s\t%s\t1..20\t3\n' \
  "$(eh_failure_threshold)" "$(eh_value_source failure_spiral_threshold default)"
printf 'urgency_sensitivity\t%s\t%s\tlow | medium | high\tmedium\n' \
  "$(eh_urgency_sensitivity)" "$(eh_value_source urgency_sensitivity default)"
printf 'judge_model\t%s\t%s\t(any model id)\tclaude-haiku-4-5-20251001\n' \
  "$(eh_judge_model)" "$(eh_value_source judge_model default)"
for k in guard_test_edits guard_no_verify guard_goal_conflict \
         session_baseline subagent_baseline post_compact_anchor \
         enable_llm_judge enable_review_agent; do
  printf '%s\t%s\t%s\ttrue | false\t(profile)\n' \
    "$k" "$(eh_get_with_profile "$k")" "$(eh_value_source "$k" profile)"
done
```

Render the output as a markdown table with columns:
**Field | Current | Source | Options | Default**.

`Source` values mean:
- `override` — the user explicitly set `CLAUDE_PLUGIN_OPTION_<field>` via
  `/plugin config functional-emotions` (or the legacy `CONFIG_` env var).
- `profile` — value derived from the headline `profile` knob.
- `default` — value is the hard-coded static default.

End with one sentence interpreting the snapshot. Examples:

- *"Profile is `balanced` (default), no overrides set — the loud-mode
  bundle is active."*
- *"Profile is `quiet`, but `mode` is overridden to `loud` — banners are
  on even though the bundle would have suppressed them."*
- *"Profile is `off`; only `enable_review_agent` is overridden to `true` —
  no primes fire, but the reviewer subagent stays available."*

Do not invent fields. If the bash block fails (e.g. `CLAUDE_PLUGIN_ROOT`
unset), report the failure and stop — don't substitute partial data.
