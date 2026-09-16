---
name: process-gate-policy
description: Use whenever starting any task that will touch a semantic model or report file, to understand the intake and phase-gate requirements — what current-task.json must record, when scoping/data-modeler/report-builder are actually required, and what self-test and self-evaluation each phase needs before the next one can begin. Read this before the first Edit/Write to a .tmdl or .pbir file, not after being blocked by it.
---

# Process Gate Policy

This is the process equivalent of `data-governance-policy`: that skill
governs *what data gets touched*, this one governs *whether the right
phase actually happened* before a report or model file gets edited. Both
are explained here for reasoning; both are actually enforced by hooks —
`policy-check.sh` for data/workspace, `process-gate.sh` for phases — not
by this document alone.

## The rule that closes the loophole

Every task — light or heavy — writes an intake record to
`.claude-governance/current-task.json` before touching a single report or
model file. Not just heavy ones. The reason: if only heavy tasks recorded
anything, "light task, no gate needed" and "heavy task that skipped
scoping" would look identical to the hook — no record either way. Making
the record mandatory for everything closes that gap. A light task's
record is one line; a heavy task's is the full phase tracking below.

## current-task.json schema

```json
{
  "task_description": "one-line summary of the actual task",
  "weight": "light | heavy",
  "started_at": "ISO timestamp",
  "phases": {
    "scoping":      { "status": "not_started | complete | failed", "self_test": "...", "self_eval": "...", "plan_approved": false },
    "modeling":     { "status": "not_started | complete | failed | not_applicable", "self_test": "...", "self_eval": "...", "entry_prompted": false, "batches": [] },
    "report_build": { "status": "not_started | complete | failed | not_applicable", "self_test": "...", "self_eval": "...", "entry_prompted": false, "batches": [] },
    "deploy":       { "status": "not_started | complete | failed | not_applicable", "self_test": "...", "self_eval": "..." }
  }
}
```

`phases` only applies to `heavy` tasks. `entry_prompted` is written by
the gate hook itself the first time it asks about entering that phase —
don't set it yourself; it's what lets the hook ask once per phase instead
of on every single file write. `plan_approved` works the same way for
the scope-approval milestone below.

**Every task starts by writing this file, before anything else.** For a
light task, that's `{"weight": "light", "task_description": "...",
"started_at": "..."}` and nothing more. For a heavy task, `scoping`
starts as `not_started` and gets updated once `scoping-analyst` returns.

## Batches: breaking heavy work into reviewable units

A `phases.modeling` or `phases.report_build` entry can carry a `batches`
array instead of relying on the flat `status` field:

```json
"report_build": {
  "batches": [
    { "name": "Page 1: Elasticity overview", "status": "not_started | in_progress | complete | failed", "self_test": "...", "self_eval": "...", "entry_prompted": false },
    { "name": "Page 2: Brand detail", "status": "not_started", "self_test": "", "self_eval": "", "entry_prompted": false }
  ]
}
```

`scoping-analyst` proposes this breakdown as part of its output — a
report page, a critical measure, a dim table are the natural unit sizes,
matching real feature-sized chunks rather than one long build. **Not
every heavy task needs batching** — a task with one small model change
and one report tweak can leave `batches` empty and use the flat `status`
field exactly as before; `process-gate.sh` falls back to that
automatically when the array is absent or empty. `bi-dev-process` has
the actual decision rule for when to propose a breakdown at all.

The gate hook processes a phase's batches strictly in order: it finds
the first batch that isn't `complete` (the "active" one) and gates entry
into it — asking once, the same way the old flat-phase entry worked —
then lets edits flow while that batch stays active. Marking a batch
`complete` (with real `self_test`/`self_eval` content, not a bare
boolean) is what advances the frontier to the next one. A batch marked
`failed` blocks everything downstream, including the other phase and
deploy, until it's resolved — a stuck batch shouldn't quietly get walked
around by starting work on the next one instead.

## The scope-approval milestone

Before any batch — modeling or report — starts, `phases.scoping` needs
`plan_approved: true`, checked separately from `status: "complete"`.
This is deliberately a distinct milestone: `status: "complete"` means
`scoping-analyst` finished its analysis; `plan_approved` means a human
actually looked at the brief, the proposed batch breakdown, and any
decision options, and said proceed. The gate hook asks for this once,
the first time any model or report file is touched, surfacing the full
brief as the reason — this is "scope and business solution agreed before
development starts" as a real, distinct checkpoint, not folded silently
into scoping finishing.

## What each phase's gate actually requires

Self-test and self-evaluation are not the same thing, and both are
required — a self-test with no evaluation is just a claim; an evaluation
with no test is just an opinion.

| Phase | Self-test (an actual check, with a real result recorded) | Self-evaluation (a checklist, recorded honestly, including doubts) |
|---|---|---|
| **Scoping** | Re-verify model-coverage claims by actually searching the model — don't assert from memory that a measure exists or doesn't. | Did I split this into distinct analytical questions? Checked coverage for each? Surfaced every real alternative (report-level measure vs. shared model change, or any other genuine choice) rather than picking one? |
| **Modeling** | Run a validation query that proves the change behaves as intended. The audit's `[SalesValue Base] − [SalesValue Matrix Base]` check is the template — a real query, a real number, recorded, not "looks right." | Does the impact check show anything unexpected? Does the result match the confirmed brief? Does it follow `nortura-semantic-standards`? |
| **Report build** | The render-verify loop (`connect-pbid`/`pbir-cli`, already required by `nortura-design` rule 16) — reload, screenshot every affected page, look, fix, repeat. | Checked against every numbered rule in `nortura-design`, not just "looks right"? |
| **Deploy** | Smoke-test against the freshly deployed target itself, not the pre-deploy version. | Does the deployed version actually match what was reviewed, or did anything change in between review and deploy? |

Recording a status of `complete` without both fields filled in honestly
defeats the entire point of this file — the hook can check that the
fields exist, it can't check that they're true. That's a human's job at
the checkpoint below.

## The human checkpoint

The gate hook uses `permissionDecision: "ask"` at the first file edit of
each new phase — a real Claude Code permission prompt, not a sentence in
the transcript that could get rushed past. The prompt's reason includes
scoping's brief so the decision has context, not just a bare "may I
proceed?" It asks once per phase, then lets subsequent edits in that same
phase flow without re-prompting — the friction is at the transition, not
on every file.

## Writing the state file on a read-only subagent's behalf

`scoping-analyst` cannot write `current-task.json` itself — it has no
`Write` tool, deliberately, so nothing can be built during scoping even
by accident. The **main session** writes the file after receiving
`scoping-analyst`'s returned brief and self-evaluation, before invoking
`data-modeler` or `report-builder`. Be honest about what this does and
doesn't guarantee: the hook can prove scoping wasn't silently *skipped*.
It cannot prove the main session summarized the subagent's findings
accurately into that file — that's a smaller gap than today's (where
skipping was invisible entirely), not a closed one.

## Staleness

`process-gate.sh` flags (asks, doesn't hard-deny) a `current-task.json`
older than 8 hours. An old record is more often leftover from a
finished or abandoned task than an accurate description of a new one —
but a long single session is legitimate, so this is a prompt to confirm,
not an automatic block.

## See also

- `data-governance-policy` — the other half of the harness, governing
  data/workspace access rather than process phase.
- `bi-dev-process` — the workflow this gate enforces; read that for the
  weighing logic that decides light vs. heavy in the first place.
