# Implementation workflow (reference)

> **Status:** synthesized by sequencing rules already stated across
> `SKILL.md` into one build order. Not sourced from a separate Nortura
> process document — if Nortura has an actual documented build process,
> reconcile it against this rather than assuming this one is authoritative.

This is the "how" behind `SKILL.md`'s rules — the order to actually apply
them in when building or editing a report page. This skill defines
constraints, not mechanics: the actual PBIR/TMDL editing is done by
handing off to the relevant implementation skill (see
`pbi-fabric-router` in the `harness` plugin), with this workflow as the
sequence to follow around that handoff.

## Build sequence

1. **Confirm the brief.** If this page started from a user story or loose
   ask, it should already have been through `report-from-user-story` —
   don't start layout work from an unconfirmed interpretation.

2. **Determine the canvas profile.** Inspect the actual page size; don't
   assume `nortura_custom`. See `design-system.md`'s canvas profiles
   section.

3. **Select a layout.** Use `SKILL.md`'s layout-selection preference
   table against the number of confirmed analytical elements from step 1
   — one dominant area, four equal panels, two rows, etc. Fall back to
   `blank` only when nothing fits, and say why.

4. **Pull slot coordinates.** From `layouts/layouts.json`, read
   `rendered_variants.<profile>.<layout>.slots` for the chosen profile
   and layout. Never reuse coordinates from a different profile.

5. **Compute visual placement.** Apply the padding formula from
   `SKILL.md`'s "Slot placement" section:

   ```text
   visual.x      = slot.x + padding
   visual.y      = slot.y + padding
   visual.width  = slot.width - (2 * padding)
   visual.height = slot.height - (2 * padding)
   ```

   using the profile-appropriate padding (16px or 11px). Apply the
   documented exceptions (edge-to-edge charts, nav/button areas, custom
   visuals with their own internal spacing) rather than padding
   everything uniformly.

6. **Place the visual.** Hand off the actual container placement to
   `pbir-format`/`pbir-cli` (community marketplace) using the computed
   coordinates. This skill supplies the numbers; it doesn't edit PBIR
   files itself.

7. **Apply the theme.** Report-level theming comes from
   `resources/theme/Nortura_template_ver2.3.json` applied through the
   normal Power BI theme mechanism. If the visual is Deneb or HTML
   Content, theme application isn't automatic — go to
   `custom-visuals.md` instead.

8. **Check for overlaps.** No two slots should overlap; this is checked
   before moving on, not caught later in review.

9. **Screenshot and verify.** Rule 16 in `SKILL.md` — reload and
   screenshot every page the change could affect via `connect-pbid`
   (`pbi-desktop` plugin) or `pbir-cli` (`reports` plugin), look at the
   rendered PNGs, fix anything wrong, and repeat until clean. This is a
   hard stop under `bi-dev-process`'s workflow, not optional polish, and
   it checks the actual rendered output — not whether the TMDL/PBIR looks
   right on paper.

## When reviewing instead of building

Don't run this sequence in reverse as a review checklist — use
`SKILL.md`'s dedicated "Review mode" section instead, which has its own
ordering and severity scale (Blocking/Major/Minor/Accepted deviation).
This workflow is for construction; that one is for audit.
