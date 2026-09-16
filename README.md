# nortura-power-bi-agentic

A Claude Code plugin marketplace for agentic Power BI / Fabric development,
built in three layers so it scales past this one engagement:

```
Layer 0 — Foundation      data-goblin/power-bi-agentic-development (public, version-pinned)
                           generic PBI/Fabric technical skills: DAX, TMDL, PBIR, Deneb, fab CLI...

Layer 1 — This repo's     plugins/harness   safety harness: data-classification + workspace-tier
           reusable                          policy engine, routing table, enforcement hooks
           practice       plugins/process   plan -> branch -> validate -> screenshot -> review -> deploy,
                                              weighted light/heavy, plus report-from-user-story;
                                              agents/ (heavy tasks only): scoping-analyst (read-only),
                                              data-modeler, report-builder

Layer 2 — This repo's     plugins/nortura-design               Nortura's approved layouts, theme, backgrounds
           client layer   plugins/nortura-semantic-standards    Nortura's naming/BPA conventions (placeholder
                                                                  defaults until Nortura's real standard is confirmed)
```

`harness` and `process` name no client and read all their per-project state
from a `.claude-governance/` folder in whatever project they're installed
into (see `templates/target-project/`) — so onboarding a second client is
"add a new `plugins/<client>-design` plugin and a new `.claude-governance/`
registry," not "fork and diverge this whole repo."

## Why a harness at all

The agent currently connects using a developer's own Fabric/Power BI
credentials, and Nortura's workspaces are only partially split into
dev/test/prod, and dataset sensitivity hasn't been fully audited yet. That
combination means there's no natural credential boundary to lean on, so
`plugins/harness` enforces policy with a `PreToolUse` hook instead of
relying on the model to remember instructions. Read
`plugins/harness/skills/data-governance-policy/SKILL.md` for the full
policy, and `plugins/harness/scripts/policy-check.sh` for the actual
enforcement logic — the skill explains the policy, the script is the
guarantee.

## Install

```bash
# Foundation
claude plugin marketplace add data-goblin/power-bi-agentic-development
claude plugin install pbip@power-bi-agentic-development
claude plugin install pbi-desktop@power-bi-agentic-development
claude plugin install semantic-models@power-bi-agentic-development
claude plugin install reports@power-bi-agentic-development
claude plugin install fabric-cli@power-bi-agentic-development
claude plugin install tabular-editor@power-bi-agentic-development

# This marketplace
claude plugin marketplace add <your-org>/nortura-power-bi-agentic
claude plugin install harness@nortura-power-bi-agentic
claude plugin install process@nortura-power-bi-agentic
claude plugin install nortura-design@nortura-power-bi-agentic
claude plugin install nortura-semantic-standards@nortura-power-bi-agentic
```

Then, in the actual Nortura Power BI project repo (not this one), follow
`templates/target-project/README.md` to set up `.claude-governance/` and
`.claude/settings.json`. Without that step, the harness fails closed by
design — every remote write and row-level query is blocked until the
registries exist.

## Scope

This project covers Power BI/Fabric **reporting and semantic modeling**.
Fabric's wider data-engineering surface (Lakehouses, Dataflows Gen2, Data
Pipelines) is deliberately out of scope — see `pbi-fabric-router`'s "Out
of scope" section for the full boundary, including two real gaps worth
knowing about: notebook execution and MCP-connector calls against a live
workspace currently bypass the harness hook entirely, since it only
watches `Bash` commands matching `fab`/`tabular-editor` patterns.

## What's still missing before this is fully usable

- `plugins/nortura-design/skills/nortura-report-design/` still needs
  `layouts/layouts.json`, `resources/theme/Nortura_template_ver2.3.json`,
  `resources/source/Bakgrunner_PP.pptx`, and the background preview PNG —
  none of these were part of the original upload. The three
  `references/*.md` files are now present, but were drafted by expanding
  the skill's own content, not sourced from Nortura's real design
  documentation — reconcile once the real theme/layout files are added.
- `plugins/nortura-semantic-standards/resources/naming-conventions.json`
  holds generic star-schema defaults, not Nortura's actual naming/BPA
  standard — confirm or replace every field before treating it as real.
- Real workspace GUIDs, tiers, and dataset classifications in
  `templates/target-project/.claude-governance/` — currently placeholders.
- `owner`/`author` fields across `.claude-plugin/plugin.json` and
  `marketplace.json` are placeholders — fill in your actual name/team.
- A move from personal credentials to a scoped service principal for
  `fab`/Tabular Editor operations, once the current setup has proven out.

## Adding a second client

1. Add `plugins/<client>-design` with that client's layout/theme/branding
   skill, following the shape of `plugins/nortura-design`.
2. List it in `.claude-plugin/marketplace.json`.
3. Stamp out a new `.claude-governance/` registry in that client's project
   repo from `templates/target-project/`.
4. Don't touch `plugins/harness` or `plugins/process` unless the change is
   genuinely client-agnostic — if it only makes sense for one client, it
   belongs in that client's plugin.
