---
name: report-from-user-story
description: Use when asked to build a Power BI report, page, or visual starting from a user story, stakeholder request, business ask, or loosely-specified requirement (e.g. "as a regional manager I want to see..." or "can we get a view of on-time delivery by plant"). Turns the ask into an analytical brief before any layout or visual work starts. Not needed when the requirement is already a precise, unambiguous spec — go straight to the relevant skill in that case.
---

# Report From User Story

A user story tells you what someone wants to be able to *decide*, not what
chart to draw. Skipping straight to layout and visuals from a one-line ask
is how you end up with a technically correct report that answers the wrong
question. This skill is the translation step between the two, and it
comes before `pbi-fabric-router` gets involved in picking implementation
skills.

## Steps

1. **Extract the actual decision.** Who is asking, and what will they do
   differently once they have this? "As a regional manager I want to see
   sales by region" is really "I need to know which regions are behind
   target so I can act on it" — that's a different (and usually simpler,
   more specific) report than a generic sales-by-region table.

2. **Split into distinct analytical questions.** A single user story often
   bundles two or three real questions ("show me delivery performance" can
   mean on-time %, trend over time, *and* worst-offending plants). Each
   one may want its own visual, or even its own page — don't force them
   into one chart because they arrived in one sentence.

3. **Check what the semantic model can already answer.** For each
   question, confirm the needed measures, dimensions, and grain exist.
   If they don't, that's model work, not report work — hand off to
   `semantic-models`/`dax`, and treat the task as **heavy** under
   `bi-dev-process` even if the report side would otherwise be light,
   since you're now changing something other reports may depend on.

4. **Confirm the brief before building anything.** Restate the
   interpreted analytical question(s) in plain language and get a quick
   yes from whoever asked. This is the cheapest point in the whole process
   to catch a misread — far cheaper than catching it after a page is
   built. Don't skip this because the story seemed obvious; that's
   usually when it isn't.

5. **Default to native visuals, one per confirmed question.** Only reach
   for Deneb/R/Python/SVG when a question genuinely can't be expressed
   natively — `nortura-report-design` already says not to use a custom
   visual to reproduce what a native one would do just as well; this is
   that rule applied at the requirements stage, before you've built
   anything to have to walk back.

6. **Pick page purpose and layout from the confirmed question count**,
   using the client design skill (`nortura-design` here) — the number of
   analytical elements you settled on in step 2 is what drives layout
   choice there, not the number of sentences in the original story.

7. **Hand off to `bi-dev-process`** at the weight the work actually turned
   out to be. A pure report build against existing measures is often
   light-to-medium; anything that touched the model in step 3 is heavy.

## What this looks like when it's skipped

The failure mode isn't "wrong chart type," it's "correct-looking report
that doesn't answer what was asked" — a trend line when the ask was
really about outliers, a table when the ask was really about a threshold
being crossed. That kind of miss survives review because nothing about it
looks broken; it only shows up when the stakeholder actually tries to use
it. That's why step 4 exists.

## See also

- `pbi-fabric-router` (harness plugin) — once the brief is confirmed, use
  this to route each piece (model changes, visuals, layout) to the right
  implementation skill.
- `data-governance-policy` (harness plugin) — check dataset classification
  before previewing live data while confirming the brief; a mocked-up
  layout with placeholder numbers is often good enough for step 4.
