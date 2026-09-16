#!/bin/bash
# SessionStart hook.
# Fires at the start (and resume/clear/compact/fork) of every session in a
# project that has this plugin enabled. Reads the project's governance
# registries (if present) and injects a short status reminder into context,
# so the policy applies regardless of which technical skill ends up handling
# the task.
#
# This script only informs Claude. The actual gate is policy-check.sh
# (PreToolUse). Never rely on this reminder alone to enforce anything.

set -euo pipefail

GOV_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude-governance"
WS_FILE="${GOV_DIR}/workspaces.json"
DC_FILE="${GOV_DIR}/data-classification.json"

if [ -f "$WS_FILE" ] && [ -f "$DC_FILE" ]; then
  ws_count=$(jq '.workspaces | length' "$WS_FILE" 2>/dev/null || echo "?")
  dc_count=$(jq '.datasets | length' "$DC_FILE" 2>/dev/null || echo "?")
  ws_default=$(jq -r '.default_tier // "single_unseparated"' "$WS_FILE" 2>/dev/null || echo "single_unseparated")
  dc_default=$(jq -r '.default_classification // "sensitive_personal"' "$DC_FILE" 2>/dev/null || echo "sensitive_personal")
  status="Governance registry loaded from ${GOV_DIR}: ${ws_count} workspace(s) on file (unlisted workspaces default to tier '${ws_default}'), ${dc_count} dataset classification(s) on file (unlisted datasets default to '${dc_default}')."
else
  status="No .claude-governance registry found at ${GOV_DIR}. Until it is set up, every remote Power BI/Fabric write and every row-level data query is blocked by default (fail closed). Run the classification/workspace audit first — see the data-governance-policy skill."
fi

jq -n --arg status "$status" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("HARNESS ACTIVE (plugin: harness).\n" + $status + "\n\nPolicy summary: reading schema, DAX, TMDL, and metadata is always allowed. Row-level data access, remote workspace writes, and tenant-admin actions are gated by the .claude-governance registries and enforced by a PreToolUse hook — not by this reminder alone. Before proposing or running any remote write, state the target workspace name, its GUID, and its classification. See the data-governance-policy and pbi-fabric-router skills for the full policy and routing table.")
  }
}'
