---
name: data-governance-policy
description: Use whenever a task touches a remote Power BI or Fabric workspace, queries or previews data from a semantic model, or involves credentials/tenant settings. Explains the data-classification and workspace-tier policy that governs what this agent may do, and where the registries and enforcement live. Read before proposing any remote write, any row-level data query, or any tenant-admin action.
---

# Data Governance Policy

This skill is the human-readable policy. **The actual enforcement is a
`PreToolUse` hook** (`plugins/harness/hooks/hooks.json` ->
`scripts/policy-check.sh`), which reads the registries below and can
block, ask, or allow a command regardless of what this document says. Treat
this skill as "how to reason and what to tell the user," not as the
guarantee itself.

## Why personal credentials change the design

This project currently connects via the developer's own Fabric/Power BI
credentials, not a scoped service principal. That means there is no
technical ceiling separate from the human's own permissions — if the human
is a workspace admin somewhere, so is any command run on their behalf.
Two consequences:

1. The registries below (not the credential) are the real boundary. Keep
   them accurate.
2. Every remote write should be treated as something the *human* is really
   doing, with the agent as a proxy — so state the target workspace name,
   its GUID, and its classification before running anything remote, even
   when the hook would also catch a bad case.

Moving to a scoped service principal with write access limited to a
designated dev workspace is the long-term fix. Until then, this registry +
hook pair is doing the job a credential boundary would otherwise do.

## The registries

Two JSON files live in the *target project's* `.claude-governance/`
folder (not inside this plugin — that's what makes the harness reusable
across clients: the plugin is generic, the registry is per-project):

- `.claude-governance/workspaces.json` — maps workspace GUIDs to an
  environment tier.
- `.claude-governance/data-classification.json` — maps dataset names to a
  sensitivity classification.

If either file is missing, the hook fails closed: remote writes and
row-level queries are blocked until the registries exist. This is
intentional — "we haven't classified this yet" should behave the same as
"this is sensitive," not the same as "this is fine."

## Workspace tiers

| Tier | Local file edits | Autonomous remote write | Remote write | Tenant admin |
|---|---|---|---|---|
| `dev` | allowed | allowed | — | never |
| `test` | allowed | never | asks every time | never |
| `prod` | allowed (prep only) | never | never — a human runs it | never |
| `single_unseparated` (workspace has no dev/test/prod split) | allowed | never | asks every time | never |
| not in the registry | falls back to `workspaces.json`'s `default_tier`, which should stay `single_unseparated` until the environment is properly split | | | |

`single_unseparated` is expected to be the common case right now, since
only some of Nortura's workspaces have dev/test/prod separation. Don't
treat it as a lesser tier to work around — it's the honest state of a
workspace that hasn't been split yet, and it should feel at least as
strict as `test`.

**"Remote write" above also means "connecting to live data."** The gate
isn't limited to publish/deploy — `connect-pbid` and `pbir-cli` (the
tools behind the render-verify loop in `bi-dev-process`) go through the
same tier check before connecting, not just before writing. A
`connect`-style command doesn't always carry the workspace's GUID in its
command text — it can be implicit in the report file's own connection
settings instead. When the hook can't identify the target, it never
silently allows just because the default tier happens to be permissive;
"unidentified" always resolves to at least an `ask`, with a reason that
says so plainly rather than pretending to know what it's connecting to.

## Data classification

| Classification | Schema / DAX / TMDL read | Row-level query | Full export |
|---|---|---|---|
| `not_sensitive` | always | allowed | human-approved |
| `sensitive_business` | always | aggregated/sampled only | never |
| `personal` | always | aggregated/TOPN-capped, PII columns redacted, never echoed into the transcript | never |
| `sensitive_personal` | always | never | never |
| not in the registry | falls back to `data-classification.json`'s `default_classification`, which should stay `sensitive_personal` | | |

A dataset that "might contain" personal or sensitive personal data (the
honest answer for most Nortura models right now) should be entered as
`sensitive_personal` until someone actually checks — the registry entry
records a decision, not a guess.

## What this agent never does, regardless of registry state

- Runs tenant-admin operations (`fab admin`, tenant settings, delegated
  overrides) autonomously. A human with admin rights runs these directly.
- Writes to a workspace tiered `prod`.
- Treats "the hook didn't block it" as proof an action was safe — the hook
  is pattern-matching on command text, not a full parser. If a command's
  intent is ambiguous, say so and ask, rather than relying on the hook to
  catch it.
- Treats notebook execution or MCP-connector calls against a live
  workspace as governed by this hook. `policy-check.sh` only matches
  `Bash` commands with `fab`/`tabular-editor`/`Publish-`/`Deploy-`-style
  patterns — a `sempy`/`evaluate_dax` notebook cell or an MCP tool call
  reaches the same data through a door this hook doesn't watch. See
  `pbi-fabric-router`'s "Out of scope" section; treat both as unscoped
  and unguarded until the hook is actually extended to cover them.

## First task for a new project: the classification audit

Before this agent does any live-data work in a project, walk every
workspace and dataset it can reach — schema/column-name level only, zero
row access — and propose a first-pass entry for both registries. Present
the proposed classifications to a human for confirmation; don't write the
registry files yourself without sign-off. For anything touching personal
or sensitive personal data, that sign-off should include Nortura's data
protection contact, since GDPR applies and this may need a DPIA — that's
a compliance call for them, not something this skill can clear.

## See also

- `pbi-fabric-router` (this plugin) — which skill/plugin to reach for once
  the governance question is settled.
- `bi-dev-process` (process plugin) — the plan → branch → validate →
  review → deploy workflow this policy sits inside.
