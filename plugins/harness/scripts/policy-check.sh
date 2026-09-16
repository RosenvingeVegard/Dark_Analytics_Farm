#!/bin/bash
# PreToolUse hook (matcher: Bash).
#
# This is a deterministic backstop for commands that plausibly touch a
# remote Power BI / Fabric workspace: writing (fab CLI, Tabular Editor
# CLI, PowerShell publish/deploy cmdlets), querying, or *connecting*
# (connect-pbid, pbir-cli) — connecting to live data is gated the same
# way as a write, not treated as free just because nothing gets changed.
# It is intentionally simple pattern-matching, not a full command parser
# — treat it as one layer of defense-in-depth, not a guarantee. Pair it
# with:
#   - permissions.deny rules in the target project's .claude/settings.json
#   - moving off personal credentials to a scoped service principal
#     (see the data-governance-policy skill)
#
# Policy (see .claude-governance/workspaces.json for the registry):
#   dev                -> allow, no prompt
#   test                -> ask (normal permission prompt) every time
#   single_unseparated  -> ask (normal permission prompt) every time
#   prod                -> deny, always. A human runs prod actions directly.
#   unknown workspace   -> falls back to workspaces.json's default_tier
#   unidentified target -> always at least ask, even if default_tier is
#                          'dev' — see below. A connect-style command may
#                          not carry the workspace GUID in its command
#                          text at all (it can live inside the report
#                          file's own connection settings instead); when
#                          that happens this hook cannot tell dev from
#                          prod, so it never silently allows.
#
# Data policy (see .claude-governance/data-classification.json):
#   any command that looks like a data query and references a dataset
#   classified "sensitive_personal" or "personal" is denied outright.
#   Aggregated/sampled access to "personal" data should go through
#   TOPN/aggregation patterns reviewed separately; this hook only stops the
#   worst case (raw row-level pulls), it does not approve the safe case.

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

deny() {
  local reason="$1"
  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

ask() {
  local reason="$1"
  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# Only look at commands that plausibly touch a remote workspace or a
# semantic model's data — including establishing a live connection, not
# just writing or querying. connect-pbid/pbir-cli are included on the
# assumption they're invoked as CLI commands; if either is actually
# reached through a non-Bash path (an MCP tool, for instance), this hook
# never sees it at all — same class of gap as the notebook/MCP one
# documented in data-governance-policy.
if ! echo "$command" | grep -qiE 'fab[[:space:]]|tabular-?editor|te2?\.exe|te3\.exe|\bte\b|Publish-|Deploy-|publish\.ps1|connect-pbid|pbir-cli'; then
  exit 0
fi

# Tenant-admin operations are never autonomous, registry or not.
if echo "$command" | grep -qiE 'fab[[:space:]]+admin|tenant-?setting'; then
  deny "Tenant-admin operations are never run autonomously by this agent. A human with admin rights runs this directly."
fi

GOV_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude-governance"
WS_FILE="${GOV_DIR}/workspaces.json"
DC_FILE="${GOV_DIR}/data-classification.json"
TASK_FILE="${GOV_DIR}/current-task.json"

if [ ! -f "$WS_FILE" ]; then
  deny "No .claude-governance/workspaces.json found in this project. Remote Power BI/Fabric operations are blocked by default until the workspace registry is set up. See the data-governance-policy skill."
fi

# Deploy-specific gate: a publish/deploy command for a heavy task must
# have a completed report_build phase (or the task must not have needed
# one) before it's allowed to run at all, regardless of workspace tier.
# This is the "testing is part of every gate" requirement applied to the
# one step that actually ships something — see process-gate-policy.
# Batch-aware: if report_build has a batches array, ALL batches must be
# complete, not just the flat status field.
if echo "$command" | grep -qiE 'publish|Publish-|Deploy-|publish\.ps1' && [ -f "$TASK_FILE" ]; then
  task_weight=$(jq -r '.weight // empty' "$TASK_FILE")
  if [ "$task_weight" = "heavy" ]; then
    rb_batch_count=$(jq -r '.phases.report_build.batches // [] | length' "$TASK_FILE")
    if [ "$rb_batch_count" -gt 0 ]; then
      incomplete=$(jq -r '[.phases.report_build.batches[] | select(.status != "complete")] | length' "$TASK_FILE")
      if [ "$incomplete" -gt 0 ]; then
        deny "This task's report_build phase has ${incomplete} of ${rb_batch_count} batch(es) not yet complete. Every batch's render-verify loop and self-evaluation need to finish before anything is published — see process-gate-policy."
      fi
    else
      rb_status=$(jq -r '.phases.report_build.status // "not_started"' "$TASK_FILE")
      if [ "$rb_status" != "complete" ] && [ "$rb_status" != "not_applicable" ]; then
        deny "This task's report_build phase is '${rb_status}', not complete. The render-verify loop and self-evaluation need to finish before anything is published — see process-gate-policy."
      fi
    fi
  fi
fi

# Data-classification check runs FIRST and can override everything else,
# including a 'dev' workspace tier: sensitive data doesn't become safe just
# because the environment is dev. Block commands that look like a data
# query against a dataset registered as personal/sensitive_personal.
if [ -f "$DC_FILE" ] && echo "$command" | grep -qiE 'evaluate|topn|summarize|\bquery\b|--query|-q '; then
  restricted_hit=$(jq -r --arg cmd "$command" '
    [ .datasets // [] | .[] | select((.classification == "sensitive_personal") or (.classification == "personal")) | select(.dataset_name as $n | $cmd | test($n; "i")) ] | .[0].dataset_name // empty
  ' "$DC_FILE")
  if [ -n "$restricted_hit" ]; then
    deny "This command looks like a data query against '${restricted_hit}', which is classified personal/sensitive_personal. Row-level access is not permitted; use schema/metadata only, or route through an explicitly reviewed, aggregated query."
  fi
fi

default_tier=$(jq -r '.default_tier // "single_unseparated"' "$WS_FILE")
tier=$(jq -r --arg cmd "$command" --arg def "$default_tier" '
  ( .workspaces // [] | map(select(.id as $id | $cmd | test($id; "i"))) | .[0].tier ) // $def
' "$WS_FILE")
ws_name=$(jq -r --arg cmd "$command" '
  ( .workspaces // [] | map(select(.id as $id | $cmd | test($id; "i"))) | .[0].name ) // empty
' "$WS_FILE")

if [ -n "$ws_name" ]; then
  target_desc="workspace '${ws_name}'"
else
  ws_name="an unidentified workspace"
  target_desc="an unidentified workspace — its GUID doesn't appear in this command, likely because it's a connect/reload action whose target lives inside the report file's own connection settings rather than the command line. Confirm what this actually connects to before approving."
  # Never silently allow an unidentified target, even if default_tier
  # happens to be 'dev' — "we don't know what this is" should never
  # resolve the same as "we know it's safe".
  if [ "$tier" = "dev" ]; then
    tier="single_unseparated"
  fi
fi

case "$tier" in
  dev)
    exit 0 # allow
    ;;
  test|single_unseparated)
    ask "Remote action against ${target_desc} (tier: ${tier}). This tier requires explicit confirmation on every remote write or connection, not just once per session."
    ;;
  prod)
    deny "Workspace '${ws_name}' is tier 'prod'. This agent never writes to or connects with prod autonomously. Run this command yourself, or promote through the deployment pipeline."
    ;;
  *)
    deny "Workspace '${ws_name}' resolved to an unrecognized tier '${tier}'. Defaulting to deny. Check .claude-governance/workspaces.json."
    ;;
esac
