---
name: nortura-report-design
description: Nortura-specific Power BI report design system. Use when creating, modifying, reviewing, or standardizing Nortura Power BI report pages, including native Power BI visuals, Deneb visuals, HTML Content visuals, page backgrounds, layout selection, visual placement, spacing, theme application, and visual consistency. Invoke whenever the user asks for a report to follow Nortura design, use the Nortura template, reproduce a Nortura layout, position visuals, choose a background, review report design, or build custom visuals that must match Nortura styling.
---

# Nortura Power BI Report Design

Use this skill as the enterprise design constraint layer on top of the generic Power BI report tooling.

This skill defines **how Nortura reports should look and be composed**. It does not replace generic Power BI, PBIR, Deneb, or HTML tooling. Route technical implementation to the appropriate report/custom-visual skill (see `pbi-fabric-router` in the `harness` plugin), while retaining the Nortura rules in this skill.

## Critical rules

1. Support both approved canvas profiles: **Nortura custom 1819 × 1030** and **standard widescreen 16:9 (1280 × 720)**.
2. Detect the target page size before placing any visual. Never assume 1819 × 1030.
3. Use `layouts/layouts.json` to select the matching rendered layout variant for the target canvas.
4. Apply the approved Nortura theme from `resources/theme/Nortura_template_ver2.3.json`.
5. Do not invent arbitrary page layouts when an approved Nortura layout can satisfy the requirement.
6. Select a layout from `layouts/layouts.json` based on analytical hierarchy.
7. Position visual containers using the exact slot coordinates in the selected layout.
8. Use **16 px internal padding** inside content slots by default.
9. Keep visual backgrounds transparent when the approved page background already supplies the white rounded panel.
10. Do not add duplicate shadows, cards, panels, gradients, or decorative containers over the approved background.
11. Use the approved Nortura palette. Do not introduce arbitrary colors.
12. Default font is **Arial** unless the approved theme changes.
13. Native Power BI visuals, Deneb, and HTML Content must follow the same page-level design system.
14. For Deneb or HTML Content, read `references/custom-visuals.md`; theme behavior must be applied explicitly inside the custom visual.
15. Do not use custom visuals merely to reproduce a native visual that already satisfies the analytical requirement.
16. Screenshot and visually verify the finished page — every page the
    change could affect, not just the one edited — via `connect-pbid` or
    `pbir-cli` before declaring design work complete. This is a hard stop
    under this project's `bi-dev-process`, not optional polish, and it's
    always available once `pbi-desktop`/`reports` are installed — not a
    conditional nice-to-have.

## Canvas profiles

Nortura reports may use more than one approved page size.

Supported profiles:

- `nortura_custom` — 1819 × 1030, derived from the original Nortura design template.
- `widescreen_16_9` — 1280 × 720, standard 16:9.

Before layout work:

1. Inspect the report page size.
2. Select the matching canvas profile in `layouts/layouts.json`.
3. Use coordinates from `rendered_variants.<profile>.<layout>.slots`.
4. Do not reuse pixel coordinates from one profile on another profile.
5. If an approved background image is used, use a background exported for the same canvas profile.

The original layout geometry is also stored as normalized coordinates. These are the canonical proportional layout definition and allow additional page sizes to be generated without redesigning the layout.

### Padding

Use proportional padding:

- 1819 × 1030 → 16 px default.
- 1280 × 720 → 11 px default.

Do not force 16 px at every resolution.

## Before creating a page

Determine:

- page purpose;
- primary analytical question;
- number of major analytical elements;
- whether persistent navigation is required;
- whether the page requires native visuals only or includes Deneb/HTML;
- which layout best represents the information hierarchy;
- which workspace/dataset this page will connect to, and its tier/classification per `data-governance-policy` — this matters even for design work, since a page against a `sensitive_personal` dataset shouldn't be previewed with live row-level data.

Then read:

- `references/design-system.md`
- `layouts/layouts.json`

For implementation details, read `references/implementation-workflow.md`.

## Layout selection

Use the following preference:

- one dominant analytical area → `header_main` or `main_only`;
- one dominant area with left navigation → `header_main_left_nav` or `main_left_nav`;
- four equal elements → `four_panel`;
- one dominant left + two supporting right → `dominant_left_two_right`;
- two supporting left + one dominant right → `two_left_dominant_right`;
- two full-width stacked elements → `two_rows`;
- two rows + left navigation → `two_rows_left_nav`;
- two columns + left navigation → `two_columns_left_nav`.

Use `blank` only when no approved layout can express the requirement and explain the deviation.

## Slot placement

A slot is the outer approved panel geometry.

By default, place the actual Power BI visual inside the slot using the padding defined for the selected canvas profile.

For `nortura_custom` (1819 × 1030):

```text
padding = 16
```

For `widescreen_16_9` (1280 × 720):

```text
padding = 11
```

Then:

```text
visual.x      = slot.x + padding
visual.y      = slot.y + padding
visual.width  = slot.width - (2 * padding)
visual.height = slot.height - (2 * padding)
```

Exceptions:

- edge-to-edge charts where additional padding harms readability;
- navigation/button areas intended to use the full slot;
- custom visuals whose internal specification already provides the required spacing.

Do not overlap slots.

## Theme and color

The theme is the source of truth for standard Power BI visual formatting.

Primary approved color sequence:

1. `#084411`
2. `#F6C04B`
3. `#78993E`
4. `#546B86`
5. `#D79798`
6. `#A1869B`
7. `#BC6365`

Use stable semantic color meaning across pages.

## Native visuals

Prefer native Power BI visuals when they communicate the requirement effectively.

Do not manually override theme defaults without a clear analytical reason.

Avoid unnecessary chart titles when the page/header already communicates context.

Keep slicers grouped and predictable.

## Deneb and HTML Content

Read `references/custom-visuals.md`.

The key rule is:

> Custom visuals must inherit the Nortura design language explicitly, even where the Power BI theme does not automatically style their internal rendering.

Deneb and HTML Content still use the same approved page layouts and exact visual container coordinates as native visuals.

## Review mode

When reviewing an existing Nortura report:

1. identify the page canvas profile and verify that it is an approved Nortura size;
2. identify the nearest approved layout;
3. compare visual coordinates to approved slots;
4. check visual backgrounds and duplicate panel effects;
5. check theme usage;
6. check color consistency;
7. check typography;
8. check spacing;
9. check accessibility;
10. check whether custom visuals follow `references/custom-visuals.md`.

Report deviations as:

- **Blocking** — breaks Nortura layout/theme or usability;
- **Major** — materially inconsistent styling or hierarchy;
- **Minor** — polish/spacing issue;
- **Accepted deviation** — intentional exception with a documented rationale.

## Source assets

- `resources/theme/Nortura_template_ver2.3.json` — approved Power BI theme. **Still missing** — add this before trusting the theme/color sections.
- `resources/source/Bakgrunner_PP.pptx` — approved background/layout source. **Still missing.**
- `resources/backgrounds/layout-header-main-preview.png` — preview of the primary background. **Still missing.**
- `layouts/layouts.json` — exact layout coordinates derived from the PowerPoint source. **Still missing** — this is the load-bearing one; layout selection and slot placement have nothing to read until it exists.
- `references/design-system.md`, `references/implementation-workflow.md`, `references/custom-visuals.md` — now present, but drafted by expanding this file's own content rather than sourced from Nortura's original design documentation. Reconcile against the real template once `resources/theme/` and `layouts/` are added.

## See also

- `pbi-fabric-router` (harness plugin) — hands off to `pbir-format`/`pbir-cli`/`deneb-visuals` etc. for actual implementation once the design decisions here are made.
- `bi-dev-process` (process plugin) — the screenshot-verification step in rule 16 is a hard gate in that workflow, not just a recommendation here.
