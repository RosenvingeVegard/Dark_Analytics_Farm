---
name: nortura-semantic-standards
description: Use when naming tables/measures/columns in a Nortura semantic model, when reviewing a model for naming or documentation consistency, or when generating/updating Best Practice Analyzer rules for Nortura models. Complements the generic standardize-naming-conventions and bpa-rules skills with Nortura's actual house standard, where one has been confirmed.
---

# Nortura Semantic Model Standards

This is the semantic-model analogue of `nortura-design`: a place for
Nortura's house standards to live so every model looks and is documented
the same way, instead of each model reflecting whoever built it.

**Read this before relying on it:** `resources/naming-conventions.json`
currently holds generic star-schema defaults, not a confirmed Nortura
standard. Nothing in this skill should be presented to Nortura as "our
convention" until someone at Nortura has actually confirmed it. Treat it
the same way you'd treat `nortura-design`'s placeholder layout/theme
files before real assets were added — a structure to fill in, not
finished content.

## What this skill does and doesn't do

- **Does**: hold Nortura's naming, DisplayFolder, description, and
  relationship conventions as a config (`resources/naming-conventions.json`)
  that both a human and the agent can check work against.
- **Doesn't**: implement the actual enforcement mechanics. Naming audits
  go through the community `standardize-naming-conventions` skill; Best
  Practice Analyzer rule *generation* goes through the community
  `bpa-rules` skill, which owns the correct Tabular Editor rule schema.
  This skill supplies the input (what the rule should say), not the rule
  engine itself — don't hand-write BPA rule JSON here from a guess at the
  schema when a skill that actually knows it is one hop away.

## Using this for a naming/documentation review

1. Load `resources/naming-conventions.json`.
2. Hand it to `standardize-naming-conventions` as the standard to audit
   against, rather than that skill's generic defaults.
3. Report findings the same way `nortura-report-design`'s review mode
   does: Blocking / Major / Minor / Accepted deviation, since that
   severity language is already familiar from design reviews.

## Using this to generate house BPA rules

1. Turn each convention in `resources/naming-conventions.json` into a
   plain-language rule statement (e.g. "dimension tables must start with
   Dim").
2. Hand those statements to `bpa-rules` to generate the actual rule
   definitions — that skill knows the schema Tabular Editor expects; this
   skill deliberately doesn't duplicate that knowledge.
3. Store the generated rules wherever the `bpa-rules`/`tabular-editor`
   plugins expect them for this project, not inside this plugin.

## What needs real input before this is trustworthy

- Confirm or replace every field in `naming-conventions.json` with
  Nortura's actual standard, if one exists. If Nortura has no documented
  standard yet, that's worth surfacing as its own finding rather than
  quietly adopting the generic defaults as fact.
- Domain-specific naming (Nortura's own business terms for plants,
  products, production stages, etc.) isn't something this skill can
  supply — that has to come from someone who knows the business, not be
  inferred or invented.
- Any existing BPA rule files Nortura already has in Tabular Editor should
  be inventoried before generating new ones, so this doesn't create a
  second, conflicting rule set.

## See also

- `nortura-design` (design plugin) — the report-side equivalent of this
  skill; same "confirmed standard, not agent-invented" principle applies.
- `bi-dev-process` (process plugin) — a naming/documentation review is
  usually a light task; generating or changing house BPA rules that then
  get enforced tenant-wide is heavy.
