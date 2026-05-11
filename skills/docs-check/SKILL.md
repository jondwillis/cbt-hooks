---
name: docs-check
description: Scan README.md and AGENTS.md for claims that no longer match the current source-of-truth files (hooks/hooks.json, .claude-plugin/plugin.json, scripts/lib.sh, skills/*/SKILL.md). Use after editing any of those files, before committing/releasing, when the user asks about doc-drift, or when the `.claude/settings.json` soft-reminder hook has just fired pointing here.
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash
---

Audit `README.md` and `AGENTS.md` for stale claims relative to the
current state of the source-of-truth files in this repo. The README
and AGENTS.md duplicate content that lives more authoritatively in
code; this skill detects when the duplications drift.

## Sources of truth

| Aspect | Source of truth | Doc claims to verify |
|---|---|---|
| Hook triggers + primes + matchers | `hooks/hooks.json` (canonical) + `scripts/*.sh` (implementations) | README "Hooks" table; AGENTS.md hook descriptions |
| Config keys + defaults + types | `.claude-plugin/plugin.json` `userConfig` | README "Configuration" table; AGENTS.md "Config" section |
| Skill names + descriptions + auto-invocation triggers | `skills/*/SKILL.md` frontmatter (name, description) | README "Skills" table; AGENTS.md skill list |
| State-dir resolution | `scripts/lib.sh` `eh_state_dir()` + `eval/lib/paths.ts` `defaultStateDir()` | README "State" section; AGENTS.md "State" section |
| Detector functions, prime templates | `scripts/lib.sh` `eh_*` functions | Any prose in README/AGENTS that names a specific function or describes its behavior |

## Procedure

1. Read `README.md` and `AGENTS.md` in full.
2. For each source-of-truth file listed above, read it and identify
   every claim in the docs that references its content.
3. Compare. A "claim" is anything the docs assert about the source —
   a hook trigger, a config default, a skill description, a function
   name, a path. The check is: does the doc-text still match what
   the source says today?
4. Report findings as a short list. For each drift:
   - **Where**: `README.md:LINE` or `AGENTS.md:LINE`
   - **Claim**: what the doc says
   - **Truth**: what the source says (with source-file reference)
   - **Suggested fix**: the minimal edit to bring the doc back in sync
5. If no drift, say "Docs in sync with source." and stop.

## Scope notes

- Only flag **concrete drift** — a hook the README claims exists
  that isn't in `hooks.json`, a config default the README states
  wrongly, a skill the README references by old name, a function
  the README invokes that has been renamed.
- Do **not** flag "this section could be expanded" or "consider
  adding X" or "this paragraph is verbose." This skill checks
  correctness, not quality.
- Do **not** apply the fixes yourself. Report and let the user
  decide which to take.
- If you find that the docs intentionally simplify (e.g., the README
  shows 6 hook categories where `hooks.json` has 21 entries because
  the README is grouped/summarized), note that as a deliberate
  abstraction, not drift, and move on.

## Reading order

For efficiency: read the docs first (so you know what claims exist),
then read each source-of-truth file once and check it against every
relevant claim in one pass. Don't re-read sources per-claim.
