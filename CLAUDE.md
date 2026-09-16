# Dark Analytics Farm — Nortura Power BI/Fabric agentic marketplace

This is the marketplace repo itself — `harness`, `process`,
`nortura-design`, `nortura-semantic-standards` all live here. If you're
looking for the file that governs actual Power BI/Fabric development
work, that's a different `CLAUDE.md` (`templates/target-project/`,
copied into the real project repo). This one governs *editing this
repo* — skills, hooks, subagents — not using them.

## Before changing anything

1. Read `CONTRIBUTING.md` first — it has the release/versioning rules.
   This file is about judgment calls CONTRIBUTING.md doesn't cover, not
   a replacement for it.
2. Figure out which layer a change belongs to before writing it:
   - `plugins/harness`, `plugins/process` — must stay client-agnostic.
     If a change only makes sense for Nortura, it doesn't belong here,
     regardless of how small it looks.
   - `plugins/nortura-design`, `plugins/nortura-semantic-standards` —
     Nortura-specific. This is where a lesson learned from an actual
     build usually belongs, not in the harness/process plugins.
3. A skill describes policy; a hook enforces it. Don't let a skill's
   documentation say something a hook doesn't actually check — that gap
   is exactly how the `SessionStart` visibility issue and the
   `connect-pbid` gating gap happened. If you change what a hook does,
   update the skill that describes it in the same change, not later.

## Testing discipline for `plugins/harness/scripts/*.sh`

These two scripts (`policy-check.sh`, `process-gate.sh`) are the actual
guarantee behind everything else in this repo — treat changes to them
with more care than a skill or agent `.md` file, not the same care.
Before considering a change done:

1. `bash -n <script>` — syntax check. Cheap, and it has caught real bugs
   (a stray leftover `fi` from an edit that didn't reach far enough).
2. Mock-test every branch with piped JSON via stdin, covering at minimum:
   allow, ask, and deny paths; the fallback/default-tier or
   default-classification case; the "no registry file present" fail-
   closed case; and anything the specific change touches. Don't just test
   the new behavior — re-run the existing scenarios too, since a change
   in one branch's ordering can silently break another (the
   classification-check-before-tier-check ordering bug was found exactly
   this way).
3. `python3 -m json.tool` (or `claude plugin validate .`) on every JSON
   file touched, including `hooks.json` and any `plugin.json`.

## Recording usage-driven changes accurately

When a change comes from something observed in a real build (a
confidence-calibration issue, a tool reached for too early, a process
step skipped) — say what specifically prompted it in the commit message
or PR description, not just what changed. The self-evaluation discipline
this project asks of the *agent* is worth holding the *maintainer* side
to as well: "found this because X happened during the Nilsen build" is
more useful to the next person than "improved scoping-analyst."

## What not to duplicate here

Don't restate `CONTRIBUTING.md`'s versioning rules or
`process-gate-policy`'s schema in this file. Link to them. If this file
grows past a quick orientation, that's a sign the content belongs in a
skill instead.
