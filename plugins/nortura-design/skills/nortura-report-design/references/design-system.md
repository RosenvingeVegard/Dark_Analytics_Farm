# Nortura design system (reference)

> **Status:** drafted by expanding what `SKILL.md` already states, not sourced
> from Nortura's original design template. Treat every value here as
> provisional until checked against `resources/theme/Nortura_template_ver2.3.json`
> and `resources/source/Bakgrunner_PP.pptx` once those are added — this file
> should end up as a *readable expansion* of what's in the real theme file,
> not a second source of truth competing with it.

This is the deeper "why" and "what else" behind `SKILL.md`'s rule list.
Read it alongside `layouts/layouts.json` before starting page design, as
`SKILL.md`'s "Before creating a page" section says to.

## Canvas profiles

Two approved profiles exist because Nortura reports are consumed in two
different contexts: `nortura_custom` (1819 × 1030) matches the original
Nortura PowerPoint-derived template, while `widescreen_16_9` (1280 × 720)
covers standard Power BI Desktop/Service defaults for anything that
doesn't need the custom canvas. Never mix pixel coordinates between them —
each profile's layout geometry is separately derived in `layouts.json`.

## Typography

Default font is Arial (`SKILL.md`, rule 12). A specific type scale — sizes
for titles, axis labels, data labels — isn't defined anywhere in the
source material yet; pull it from `Nortura_template_ver2.3.json` once
that file is added, rather than guessing sizes here.

## Color

The seven approved colors, in the fixed sequence `SKILL.md` defines:

1. `#084411` 2. `#F6C04B` 3. `#78993E` 4. `#546B86`
5. `#D79798` 6. `#A1869B` 7. `#BC6365`

`SKILL.md` says to "use stable semantic color meaning across pages" —
meaning once a color has been assigned to represent something (a region,
a product category, a status), that assignment should hold on every page
it appears on again, not be reassigned per-chart. This skill doesn't
prescribe *which* color means what — that mapping should get documented
here once it's established on real reports, so a second report doesn't
independently invent a conflicting assignment.

## Spacing

Padding is proportional to canvas profile, not a single fixed value:

| Profile | Default padding |
|---|---|
| `nortura_custom` (1819×1030) | 16px |
| `widescreen_16_9` (1280×720) | 11px |

See `implementation-workflow.md` for how this feeds into the actual slot
placement formula.

## Backgrounds and containers

The approved page background already supplies a white rounded panel
behind each content slot. Visual backgrounds inside that slot should be
transparent — adding a second background, shadow, card, or gradient on
top of the approved one is a **Blocking** finding under review mode, not
a stylistic choice.

## Native visual conventions

- Prefer native visuals over Deneb/HTML/R/Python when they satisfy the
  analytical requirement — see `pbi-fabric-router`'s guidance that
  custom visuals aren't a substitute for a native one that already works.
- Skip chart titles the page/header context already communicates.
- Group slicers together and keep their placement predictable across
  pages, rather than scattering them per-page.
- Only override theme defaults with a documented analytical reason —
  "it looked better" isn't one.

## See also

- `implementation-workflow.md` — turning these principles into actual
  slot coordinates and PBIR edits.
- `custom-visuals.md` — applying this same palette/typography inside
  Deneb and HTML Content visuals, which don't inherit the report theme
  automatically.
