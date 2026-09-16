# Custom visuals: theme inheritance (reference)

> **Status:** applies known Deneb/Vega-Lite and HTML/CSS theming
> mechanics to the palette and typography already stated in `SKILL.md`.
> No new Nortura-specific facts are introduced here — this is technique,
> not content.

`SKILL.md`'s key rule for this area:

> Custom visuals must inherit the Nortura design language explicitly,
> even where the Power BI theme does not automatically style their
> internal rendering.

The reason this needs its own document: applying a Power BI report
theme (`Nortura_template_ver2.3.json`) automatically restyles native
visuals, but Deneb (Vega-Lite/Vega) and HTML Content visuals render their
own internal DOM or canvas — the report theme doesn't reach inside them.
Whoever builds the visual has to wire the palette and font in by hand,
every time.

## Deneb (Vega-Lite / Vega)

- **Color**: set the seven approved colors as an explicit categorical
  range rather than letting Vega-Lite pick its own scale:

  ```json
  "config": {
    "range": {
      "category": ["#084411", "#F6C04B", "#78993E", "#546B86", "#D79798", "#A1869B", "#BC6365"]
    }
  }
  ```

  Keep the same category-to-color assignment used elsewhere on the page
  (see `design-system.md`'s note on stable semantic color meaning) —
  don't let Vega-Lite's default ordering silently reassign colors.

- **Font**: set Arial explicitly across the whole spec, since Vega/Vega-Lite
  defaults to its own sans-serif otherwise:

  ```json
  "config": {
    "font": "Arial",
    "axis": { "labelFont": "Arial", "titleFont": "Arial" },
    "legend": { "labelFont": "Arial", "titleFont": "Arial" },
    "title": { "font": "Arial" }
  }
  ```

- **Background**: set `"background": null` (or `"transparent"`) at the
  top level of the spec so the approved page background's white panel
  shows through, per `SKILL.md`'s rule against duplicate panels.

- **Placement**: the visual's container is still placed using the same
  slot/padding math as a native visual (`implementation-workflow.md`,
  step 5) — Deneb doesn't get different placement rules, only different
  internal theming.

## HTML Content

- **Color**: hardcode the same seven hex values as CSS custom properties
  at the top of the visual's stylesheet, rather than repeating literals
  throughout:

  ```css
  :root {
    --nortura-1: #084411;
    --nortura-2: #F6C04B;
    --nortura-3: #78993E;
    --nortura-4: #546B86;
    --nortura-5: #D79798;
    --nortura-6: #A1869B;
    --nortura-7: #BC6365;
  }
  ```

- **Font**: `font-family: Arial, sans-serif;` on the container, inherited
  down rather than set per-element.

- **Background**: `background: transparent;` on the outermost container —
  same reasoning as Deneb above.

- **No decorative additions**: no `box-shadow`, no extra `border-radius`
  card treatment, no gradient fills — `SKILL.md`'s rule against duplicate
  shadows/cards/panels applies exactly as much to HTML Content as to
  native visuals.

## Before reaching for a custom visual at all

Confirm a native visual genuinely can't express the requirement first —
`SKILL.md` rule 15 exists because a Deneb chart that reproduces what a
native bar chart already does costs more to build and maintain for no
analytical gain. This document is about how to theme a custom visual
correctly once one is actually justified, not a reason to prefer one.

## See also

- The community marketplace's `deneb-visuals`/`svg-visuals` skills for
  the authoring mechanics themselves — this document is only the
  Nortura-specific theming contract layered on top.
