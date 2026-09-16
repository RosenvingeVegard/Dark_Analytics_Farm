#!/bin/bash
# PreToolUse hook (matcher: Edit, and separately: Write).
#
# Enforces process-gate-policy: every task, light or heavy, needs an
# intake record before touching a report/model file. Heavy tasks
# additionally require:
#   1. scoping complete AND its scope/batch breakdown explicitly approved
#      (phases.scoping.plan_approved) — the "scope and business solution
#      agreed before development" milestone — before ANY model or report
#      file, regardless of batching.
#   2. If a phase (modeling/report_build) has a non-empty "batches" array,
#      work is gated one batch at a time, in order: the first non-complete
#      batch is the "active" one, and its entry gets a single ask before
#      edits flow. A task that doesn't need batching (small heavy task)
#      just omits the array and falls back to the old flat phase-status
#      check.
#
# Only looks at Edit/Write calls targeting semantic-model or report
# definition files. Everything else passes through untouched. Same
# caveats as before: pattern-matching on a file path, not a full
# understanding of the edit — a backstop, not a guarantee. The main
# session writes current-task.json on scoping-analyst's behalf, since
# that subagent is read-only; this hook can prove the step wasn't
# silently skipped, not that it was summarized honestly.

set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

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

set_field() {
  jq "$1" "$TASK_FILE" > "${TASK_FILE}.tmp" && mv "${TASK_FILE}.tmp" "$TASK_FILE"
}

is_model_file=false
is_report_file=false
if echo "$file_path" | grep -qiE '\.tmdl$|\.SemanticModel[/\\]'; then
  is_model_file=true
fi
if echo "$file_path" | grep -qiE '\.pbir$|definition\.pbir$|\.Report[/\\]'; then
  is_report_file=true
fi
if [ "$is_model_file" = false ] && [ "$is_report_file" = false ]; then
  exit 0
fi

GOV_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude-governance"
TASK_FILE="${GOV_DIR}/current-task.json"

if [ ! -f "$TASK_FILE" ]; then
  deny "No .claude-governance/current-task.json found. Every task, light or heavy, needs an intake record (at minimum its weight) before a report/model file is touched. See process-gate-policy."
fi

age_minutes=$(( ( $(date +%s) - $(stat -c %Y "$TASK_FILE" 2>/dev/null || stat -f %m "$TASK_FILE") ) / 60 ))
if [ "$age_minutes" -gt 480 ]; then
  ask "current-task.json is over 8 hours old ($age_minutes min). Confirm this is still the active task — re-run intake if it's actually a new one — before continuing."
fi

weight=$(jq -r '.weight // empty' "$TASK_FILE")
if [ -z "$weight" ]; then
  deny "current-task.json has no 'weight' field. Intake must record light or heavy before any file is touched."
fi
if [ "$weight" = "light" ]; then
  exit 0
fi

scoping_status=$(jq -r '.phases.scoping.status // "not_started"' "$TASK_FILE")
if [ "$scoping_status" = "failed" ]; then
  reason=$(jq -r '.phases.scoping.self_eval // "no reason recorded"' "$TASK_FILE")
  deny "scoping phase is marked failed (${reason}). Resolve before any file is touched."
fi
if [ "$scoping_status" != "complete" ]; then
  deny "scoping phase is '${scoping_status}', not complete. scoping-analyst must confirm the brief (and, for report files, the model-coverage finding) before anything gets written. See process-gate-policy."
fi

plan_approved=$(jq -r '.phases.scoping.plan_approved // false' "$TASK_FILE")
if [ "$plan_approved" != "true" ]; then
  brief=$(jq -r '.phases.scoping.self_eval // "no brief recorded"' "$TASK_FILE")
  set_field '.phases.scoping.plan_approved = true'
  ask "Scope and batch breakdown ready for approval before development starts: ${brief}. Confirm the scope, the proposed batches, and any decision options before the first batch begins."
fi

phase_gate() {
  local phase="$1"
  local batch_count
  batch_count=$(jq -r ".phases.${phase}.batches // [] | length" "$TASK_FILE")

  if [ "$batch_count" -eq 0 ]; then
    local status
    status=$(jq -r ".phases.${phase}.status // \"not_started\"" "$TASK_FILE")
    if [ "$status" = "not_applicable" ]; then
      return 2
    fi
    if [ "$status" = "failed" ]; then
      local reason
      reason=$(jq -r ".phases.${phase}.self_eval // \"no reason recorded\"" "$TASK_FILE")
      deny "${phase} phase is marked failed (${reason}). Resolve before continuing."
    fi
    if [ "$status" = "complete" ]; then
      return 0
    fi
    local entry_prompted
    entry_prompted=$(jq -r ".phases.${phase}.entry_prompted // false" "$TASK_FILE")
    if [ "$entry_prompted" != "true" ]; then
      local brief
      brief=$(jq -r '.phases.scoping.self_eval // "no brief recorded"' "$TASK_FILE")
      set_field ".phases.${phase}.entry_prompted = true"
      ask "Entering ${phase} phase. Scoping's brief: ${brief}. Confirm before ${phase} files are edited."
    fi
    return 1
  fi

  local active_index
  active_index=$(jq -r "[.phases.${phase}.batches[] | .status] | map(. != \"complete\") | index(true)" "$TASK_FILE")
  if [ "$active_index" = "null" ]; then
    return 0
  fi
  local active_status active_name entry_prompted
  active_status=$(jq -r ".phases.${phase}.batches[${active_index}].status" "$TASK_FILE")
  active_name=$(jq -r ".phases.${phase}.batches[${active_index}].name" "$TASK_FILE")
  if [ "$active_status" = "failed" ]; then
    local reason
    reason=$(jq -r ".phases.${phase}.batches[${active_index}].self_eval // \"no reason recorded\"" "$TASK_FILE")
    deny "Batch '${active_name}' (${phase}) is marked failed (${reason}). Resolve before continuing to the next batch."
  fi
  entry_prompted=$(jq -r ".phases.${phase}.batches[${active_index}].entry_prompted // false" "$TASK_FILE")
  if [ "$entry_prompted" != "true" ]; then
    local total
    total=$(jq -r ".phases.${phase}.batches | length" "$TASK_FILE")
    set_field ".phases.${phase}.batches[${active_index}].entry_prompted = true"
    ask "Entering batch '${active_name}' (${phase}, $((active_index + 1))/${total}). Confirm before this batch's files are edited."
  fi
  return 1
}

if [ "$is_model_file" = true ]; then
  set +e
  phase_gate "modeling"
  result=$?
  set -e
  if [ "$result" = "2" ]; then
    deny "scoping determined no model change was needed for this task. If that finding is now wrong, re-run scoping rather than editing the model anyway."
  fi
  exit 0
fi

if [ "$is_report_file" = true ]; then
  set +e
  phase_gate "modeling"
  modeling_result=$?
  set -e
  if [ "$modeling_result" = "1" ]; then
    deny "modeling phase/batches are not yet complete. Report files can't be edited until the model side is resolved, per scoping's finding."
  fi
  phase_gate "report_build"
  exit 0
fi

exit 0
