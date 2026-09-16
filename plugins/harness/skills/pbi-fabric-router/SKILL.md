---
name: pbi-fabric-router
description: Use at the start of any Power BI or Microsoft Fabric task to decide which skill or plugin actually owns the work — report design, DAX/semantic modeling, PBIR/TMDL editing, Deneb/Python/R/SVG visuals, Fabric CLI operations, or tenant administration. Also use when a task spans more than one of these areas and the right order of operations isn't obvious.
---

# Power BI / Fabric Routing

Most of the technical capability here comes from the community
`power-bi-agentic-development` marketplace (data-goblin), not from this
plugin. This skill's job is to point at the right piece of it, and at
`nortura-design` for anything Nortura-branded. It does not replace reading
the target skill's own SKILL.md.

Before routing on anything, check `data-governance-policy` if the task
touches a remote workspace, live data, or credentials.

## Routing table

| Task looks like... | Go to |
|---|---|
| A user story, stakeholder request, or loosely-specified "can we get a view of..." ask | `report-from-user-story` (process plugin) **first** — don't jump straight to layout or visuals from an unconfirmed ask |
| Report page layout, visual placement, backgrounds, Nortura branding/theme | `nortura-design` skill (this marketplace), then hand off implementation to `pbir-format`/`pbir-cli` |
| Deneb, R, Python, or SVG custom visuals | `reports` plugin's `deneb-visuals`/`r-visuals`/`python-visuals`/`svg-visuals` skills — but check `nortura-design` first for placement/theme rules, since custom visuals must still follow the same page-level design system |
| DAX authoring, debugging, optimization | `semantic-models` plugin's `dax` skill |
| Power Query / M, query folding | `semantic-models` plugin's `power-query` skill |
| Semantic model structure, naming, refresh, lineage | `semantic-models` plugin |
| Editing TMDL or PBIR files directly | `pbip` plugin's `tmdl`/`pbir-format` skills |
| Best Practice Analyzer rules, C# scripting in Tabular Editor | `tabular-editor` plugin |
| Connecting to a live Power BI Desktop session | `pbi-desktop` plugin's `connect-pbid` skill |
| Any remote operation — publish, deploy, workspace management | `fabric-cli` plugin — but this always goes through `data-governance-policy`'s workspace-tier gate first |
| Tenant settings, delegated overrides, governance audits | `fabric-admin` plugin — always human-executed, see `data-governance-policy` |
| Evaluating a report/model from the PBIP files on disk | `review-report`/`semantic-model-auditor` agents reading the local files directly |
| Evaluating a report/model via an MCP connector | Whichever Power BI/Fabric MCP server is connected — but see "Out of scope" below, this path isn't covered by the harness hook yet |
| Semantic model naming conventions, house Best Practice Analyzer rules | `nortura-semantic-standards` skill (this marketplace) for the conventions themselves; `standardize-naming-conventions`/`bpa-rules` (community plugins) to actually apply or generate the rules |
| A thin/live-connected report needing something the model doesn't have | `scoping-analyst`'s model-coverage check decides report-level measure vs. escalating to the shared model — don't assume `data-modeler` is needed just because it's model-adjacent |
| Row-level security design or testing | `semantic-models` plugin — treat any RLS change as heavy under `bi-dev-process`, since it's an access-control change, not a display one |
| Performance diagnosis on an existing report or model | Profile first (`tabular-editor`/`semantic-model-auditor`), find the actually expensive thing, then fix — don't jump to a change before diagnosing |
| Promoting a report-level measure into the shared model | `data-modeler`, as a normal shared-model change — heavy, and it's how the governance debt from an earlier RLM decision gets paid down rather than left to accumulate |
| Impact analysis before a shared-model change | Not optional, not a separate task — it's `data-modeler`'s required first step before touching anything |
| Refactoring a thick report into a thin report against a shared model | Heavy by nature; a migration, not an edit — scope it through `scoping-analyst` like any other heavy task |
| Bookmarks, what-if parameters, drill-through interaction design | `report-builder`/`reports` plugin — behavior design, still follows `nortura-design` for anything visual it touches |
| A classification or workspace-tier audit itself | `data-governance-policy`'s "first task for a new project" — a named, recurring task, not a one-time setup step to forget about |
| A quick factual question, no artifact produced | Answer directly — no branch, no PR — but still subject to the same data-classification rules on what it's allowed to query |
| Deploying/promoting already-built content between environments | `bi-dev-process`'s staged-deploy step directly — nothing new is being built, so no scoping/modeling/report-building phase is needed |
| Multi-part task spanning several rows above | Sequence them: design/structure decisions first, then implementation skill, then `bi-dev-process` for the branch → validate → review → deploy flow |

## Out of scope

- **Fabric data-engineering artifacts** — Lakehouses, Dataflows Gen2, Data
  Pipelines, general notebook authoring. This project is scoped to Power
  BI/Fabric *reporting and semantic modeling*, not the wider Fabric
  data-engineering surface. Say so plainly if asked for one of these
  rather than stretching an existing skill to cover it.
- **Notebook execution against live semantic models.** Drafting
  `sempy`/`evaluate_dax` code is ordinary code generation and fine.
  Running it isn't covered: `policy-check.sh` only pattern-matches
  `fab`/`tabular-editor`/`Publish-`/`Deploy-`-style `Bash` commands, so a
  notebook cell calling the Fabric API directly would bypass the harness
  entirely. Don't treat notebook execution as governed until that gap is
  closed.
- **MCP-connector-based evaluation, if a Power BI/Fabric MCP server is
  ever connected.** Same caveat as notebooks — `policy-check.sh` only
  sees `Bash` tool calls today, not MCP tool calls. An MCP connector can
  reach the same sensitive data a `fab` command can, ungoverned, until
  the hook (or an equivalent gate) is extended to cover it.

## When nothing in the table fits

Say so rather than forcing a match. A genuinely new kind of task (e.g. a
new custom-visual type, a new Fabric item type) may need a new skill
added to this marketplace rather than being stretched into an existing
one — flag that as a suggestion rather than improvising deep inside an
unrelated skill's territory.
