# Dark Analytics Farm — Nortura Power BI / Fabric Agent

An AI development agent for Power BI and Fabric work at Nortura, built on
[Claude Code](https://claude.com/claude-code). It can scope a report, build
a semantic model, write DAX, build and fix report pages, and review
existing work — with built-in guardrails so it never touches sensitive
data, a live workspace, or production without asking first.

## Why this exists

AI agents are genuinely useful for Power BI development, but "let it do
whatever, hope it's right" isn't good enough once real data and real
reports are involved. This project wraps Claude Code with:

- **A real safety layer** — it checks what data is sensitive and which
  workspace is production *before* it acts, not after. Enforced by actual
  code, not just written policy the agent is trusted to remember.
- **A real development process** — scope and agree the work with you
  first, build it in small reviewable steps, test as it goes, and never
  skip straight to "done" without you seeing it.
- **Nortura's own standards** — report design and naming conventions
  layered on top, so the output looks and feels consistent, not generic.

## What you get

| | |
|---|---|
| 🛡️ **Harness** | The safety rules — what data it's allowed to touch, which workspace is safe to write to, and when it has to stop and ask you. |
| 📋 **Process** | How work actually gets done — scoping first, then building in small reviewable batches, with testing and a check-in built into every stage. |
| 🎨 **Nortura Design** | Report layouts, colors, and branding matching Nortura's approved template. |
| 🏷️ **Nortura Semantic Standards** | Naming and documentation conventions for semantic models — currently a placeholder, see below. |

## Quick start

1. Install [Claude Code](https://claude.com/claude-code) if you don't have
   it yet — terminal, the desktop app's Code tab, and the VS Code/JetBrains
   extension all work the same underneath.
2. Add this marketplace and the community one it depends on, then install
   the plugins:

   ```bash
   claude plugin marketplace add data-goblin/power-bi-agentic-development
   claude plugin marketplace add RosenvingeVegard/Dark_Analytics_Farm

   claude plugin install pbip@power-bi-agentic-development
   claude plugin install pbi-desktop@power-bi-agentic-development
   claude plugin install semantic-models@power-bi-agentic-development
   claude plugin install reports@power-bi-agentic-development
   claude plugin install fabric-cli@power-bi-agentic-development
   claude plugin install tabular-editor@power-bi-agentic-development

   claude plugin install harness@Dark_Analytics_Farm
   claude plugin install process@Dark_Analytics_Farm
   claude plugin install nortura-design@Dark_Analytics_Farm
   claude plugin install nortura-semantic-standards@Dark_Analytics_Farm
   ```

3. In your actual Power BI project repo (not this one), copy in the files
   from `templates/target-project/` and follow its `README.md`. This step
   matters — without it, the agent won't touch anything remote or
   sensitive at all. That's by design: safe by default, not by accident.

Once that's done, just open Claude Code in your project and describe what
you need — it figures out the rest.

## Before you rely on this for real work

A few things are still placeholders, on purpose rather than by oversight
— using this without knowing that could give a false sense of how much is
actually configured:

- **Workspace and dataset registries** (`templates/target-project/.claude-governance/`)
  are empty examples. Until real workspace GUIDs, tiers, and dataset
  classifications are entered and signed off, the agent treats *everything*
  as maximally sensitive — which is safe, but also means it won't do much
  live-data work yet. See `data-governance-policy` for the audit this needs.
- **Nortura's real design assets** (`layouts.json`, the theme file, the
  background PPTX) haven't been added to `nortura-design` yet — those
  weren't part of the original template upload.
- **Naming/BPA conventions** in `nortura-semantic-standards` are generic
  star-schema defaults, not Nortura's confirmed standard.
- **Personal credentials, not a service principal**, by deliberate choice
  for now — see `data-governance-policy` for when and how to change that.

## Scope

This covers Power BI/Fabric **reporting and semantic modeling** — not
Fabric's wider data-engineering surface (Lakehouses, Dataflows Gen2, Data
Pipelines). Two things worth knowing even within scope: notebook
execution and MCP-connector calls against a live workspace currently
bypass the safety hook entirely, since it only watches for `fab`/`tabular-editor`-style
commands. Full detail in `pbi-fabric-router`'s "Out of scope" section.

## For maintainers: how this is organized

Built in three layers so it scales past this one project:

```
Layer 0 — Foundation      data-goblin/power-bi-agentic-development (public, version-pinned)
                           generic PBI/Fabric technical skills: DAX, TMDL, PBIR, Deneb, fab CLI...

Layer 1 — This repo's     plugins/harness   safety harness: data-classification + workspace-tier
           reusable                          policy engine, routing table, enforcement hooks
           practice       plugins/process   scoping -> optional modeling -> report build -> review ->
                                              deploy, weighted light/heavy and broken into batches;
                                              agents/ (heavy tasks only): scoping-analyst (read-only),
                                              data-modeler, report-builder

Layer 2 — This repo's     plugins/nortura-design               Nortura's approved layouts, theme, backgrounds
           client layer   plugins/nortura-semantic-standards    Nortura's naming/BPA conventions (placeholder
                                                                  defaults until Nortura's real standard is confirmed)
```

`harness` and `process` name no client and read all their per-project
state from a `.claude-governance/` folder in whatever project they're
installed into (see `templates/target-project/`) — onboarding a second
client is "add a new `plugins/<client>-design` plugin and a new
`.claude-governance/` registry," not "fork and diverge this whole repo."

**Why a harness at all:** this currently connects using a developer's own
Fabric/Power BI credentials, and Nortura's workspaces are only partially
split into dev/test/prod, and dataset sensitivity hasn't been fully
audited yet. That combination means there's no natural credential
boundary to lean on, so `plugins/harness` enforces policy with real hooks
instead of relying on the model to remember instructions. Read
`plugins/harness/skills/data-governance-policy/SKILL.md` for the policy,
and `plugins/harness/scripts/policy-check.sh` for the enforcement itself
— the skill explains it, the script is the guarantee.

**Adding a second client:**

1. Add `plugins/<client>-design` with that client's layout/theme/branding
   skill, following the shape of `plugins/nortura-design`.
2. List it in `.claude-plugin/marketplace.json`.
3. Stamp out a new `.claude-governance/` registry in that client's project
   repo from `templates/target-project/`.
4. Don't touch `plugins/harness` or `plugins/process` unless the change is
   genuinely client-agnostic — if it only makes sense for one client, it
   belongs in that client's plugin.

See `CLAUDE.md` and `CONTRIBUTING.md` for the rules that apply when
editing this repo itself.
