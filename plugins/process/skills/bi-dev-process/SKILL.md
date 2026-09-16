---
name: bi-dev-process
description: Use for any non-trivial Power BI or Fabric development task — new reports, model changes, DAX changes, deployments — to structure the work as plan, branch, validate, review, deploy with explicit human checkpoints. Not needed for read-only exploration, questions, or a single small local edit the user is watching in real time.
---

# BI Development Process

This is the client-agnostic workflow this project runs on. It assumes the
`harness` plugin is installed and its hooks are active — this skill
describes the human checkpoints; the harness enforces the hard boundaries
(see `data-governance-policy`).

## Weigh the task before doing anything

Not every task earns the full flow below. Decide the weight first, state
it to the user in one line, and scale the ceremony to match — treating a
one-measure tweak like a twelve-page report build is how people learn to
route around the process entirely.

**Before either path: write the intake record.** Every task — light or
heavy — writes `.claude-governance/current-task.json` with at least its
weight before touching a single report or model file. This isn't
optional for light tasks; see `process-gate-policy` for why (it's what
lets the gate hook tell "light, no gate needed" apart from "heavy, gate
skipped").

**Light** — proceed with hooks-only validation, no branch/PR/screenshot
ceremony required (though a commit is still fine and encouraged):
- A single measure, column, or visual-formatting change.
- The user is present, watching, and reviewing the result live.
- The change is confined to one file or one report page.
- Nothing beyond `dev` is touched, and nothing certified/shared changes.

**Heavy** — run the full flow:
- Anything touching a semantic model's structure: new tables, relationships,
  or a measure that other reports already depend on.
- **Any change to a shared/published semantic model, even a small one and
  even reached through a live-connected thin report.** Weight this by
  the model's blast radius, not the requesting report's size — see
  "Roles for heavy tasks" below.
- A new report, a new page, or a page rebuilt from a user story (see
  `report-from-user-story` — that skill's output almost always lands here,
  since it usually means new measures plus new layout, not just a tweak).
- Anything that will be deployed to `test` or `prod`.
- Anything spanning more than a couple of files, even if each individual
  edit looks small on its own.

**Stays light even though it touches "the model" in a loose sense:**
- A report-level measure added to a single thin report. It doesn't touch
  the shared model and doesn't affect any other report — see
  `scoping-analyst`'s model-coverage check below for how this gets
  decided rather than assumed.

**Escalate mid-task, don't finish light.** A task that started as "just
rename this measure" is heavy the moment you discover it's used on six
pages, or that renaming it breaks a certified dataset's contract with
downstream reports. Say so and switch, rather than finishing under the
lighter process because that's what you already started.

The harness's data-governance and workspace-tier gates (see
`data-governance-policy`) apply regardless of weight — "light" reduces
process ceremony, it never reduces what the hooks enforce.

## Roles for heavy tasks

Light tasks stay single-agent — no role separation, no overhead, just the
main session doing the work with hooks validating as it goes. Heavy tasks
use three subagents in this plugin, each with a real tool restriction,
not just a persona label, and each gated by `process-gate.sh` — not just
described as required, actually blocked without it:

1. **`scoping-analyst`** — read-only, cannot edit or write a single file.
   Turns the ask into a confirmed brief, checks whether the existing
   model already covers it, surfaces alternatives (report-level measure
   vs. shared model change, or any other genuine choice — always at
   least two real options, not one proposal to rubber-stamp) for a human
   to decide, and proposes a batch breakdown for anything beyond a
   trivial build. Nothing gets built until this phase produces a
   confirmed, written brief — the main session then writes
   `phases.scoping` into `current-task.json` with `status: "complete"`
   and both a `self_test` and `self_eval` filled in
   (`process-gate-policy` has the exact requirements). Until that write
   happens, `process-gate.sh` denies every model/report file edit — and
   even once it's complete, `process-gate.sh` separately asks for
   explicit approval of the scope and batch breakdown before batch 1
   starts (see "The scope-approval milestone" below).
2. **`data-modeler`** — only invoked when `scoping-analyst` found the
   task needs an actual shared or local model change. Works through its
   batches (if any) one at a time, runs an impact check before changing
   anything, surfaces modeling-approach tradeoffs the same way scoping
   does, and records a real validation-query result as its self-test
   before each batch's (or the phase's) `status` becomes `complete`.
3. **`report-builder`** — builds the report, one batch at a time (a page,
   a feature) if the brief was broken down that way, including any
   report-level measure `scoping-analyst` decided on, following
   `nortura-design` and running the render-verify loop as its self-test
   per batch. Can also be used directly for light tasks that just need a
   report edit, without the other two phases or any gate involved.

Isolated context between subagents means the brief has to be written
down explicitly at each handoff — don't assume the next phase can see
this conversation.

## Batching: when to break heavy work into smaller units

Not every heavy task needs a batch breakdown. `scoping-analyst` decides
this as part of scoping, using roughly this rule:

- **Batch it** when the brief spans more than one independently
  meaningful deliverable — multiple report pages, several new measures,
  a dim table plus the measures that depend on it. Natural unit sizes: a
  page, a critical measure, a dim table — not "the model" or "the
  report" as one undifferentiated blob.
- **Don't batch** a heavy task that's still just one thing — one model
  change and one report tweak that goes with it doesn't need a backlog;
  it uses the flat `phases.modeling.status`/`phases.report_build.status`
  fields directly, and `process-gate.sh` falls back to that
  automatically when no `batches` array is present.

Each batch gets its own gate: `process-gate.sh` only lets the *next*
batch start once the current one's self-test, self-evaluation, and human
confirmation are all in place — not one review at the end of a long
build, a checkpoint after every page/measure/table.

## The scope-approval milestone

"Scope and business solution agreed with the human" is a distinct,
explicit checkpoint — not the same thing as `scoping-analyst` finishing.
`process-gate.sh` enforces this as `phases.scoping.plan_approved`,
asked once, before any batch (modeling or report) can start, surfacing
the full brief, the proposed batches, and any decision options as the
reason. Claude Code's plan mode is the natural vehicle for the brief
itself — it produces a reviewable Markdown document you can comment on
inline, which is a better fit for "here's the actual scope and here are
the real options" than a single chat message.

## The flow (heavy tasks; light tasks skip to hooks + done)

1. **Intake and plan — via `scoping-analyst`.** Restate the task, use
   `pbi-fabric-router` if the routing isn't obvious, and state which
   workspace(s) and dataset(s) are in scope with their tier/classification
   from the governance registries. `scoping-analyst` produces the
   confirmed brief and model-coverage finding described above. Stop for
   approval before editing files — this maps onto Claude Code's plan
   mode, with `scoping-analyst`'s read-only tools making the "nothing
   gets touched yet" part literal rather than just stated.

2. **Branch.** All PBIP/TMDL/PBIR/DAX edits happen on a git branch. Never
   commit directly to the default branch, and never treat "the user is in
   a hurry" as a reason to skip this.

3. **Local validation.** Let the `pbip`/`pbi-desktop` plugin hooks run —
   PBIR structure, TMDL syntax, DAX reference validation, report binding
   validation, measure metadata checks. These are deterministic gates; a
   failing hook is not something to route around, it's something to fix.

4. **Visual verification — the actual render loop, not just a before/after.**
   For anything touching report pages, run: edit TMDL/PBIR → reload and
   screenshot via `connect-pbid` (`pbi-desktop` plugin) or `pbir-cli`
   (`reports` plugin) → look at the rendered PNGs for *every page the
   change could plausibly affect*, not just the one edited → fix anything
   that looks wrong (overlapping visuals, truncated labels, blank charts,
   broken layout, a visual that exists in the file but doesn't actually
   render) → repeat until clean. This is a hard stop, not an optional
   nice-to-have — don't declare a design task done on the strength of the
   TMDL/PBIR looking correct; the rendered output is what's actually
   checked.

5. **PR review.** Open a pull request; a human reviews the TMDL/PBIR diff
   before merge. Both formats are readable enough for a real review — use
   that, don't ask for a rubber stamp.

6. **Staged deploy.** Deploy to the workspace tier appropriate to what's
   being shipped, following `data-governance-policy`'s tier rules:
   `dev` can proceed with the agent driving it, `test` needs a specific
   human confirmation per deploy, `prod` is human-executed full stop.

## What "done" means

A task isn't done when the file is written. It's done when it's merged,
deployed to the workspace it needs to be in, and verified there — or when
the remaining steps are explicitly handed to a human with a clear
statement of what's left and why the agent didn't do it itself.

## Scaling this to a new client

Nothing in this skill names Nortura. A new client engagement should be
able to reuse this plugin unchanged, adding only its own
`.claude-governance/` registries and a client-specific design plugin
(see how `nortura-design` is structured) — if a change to this skill only
makes sense for one client, it belongs in that client's plugin instead.
