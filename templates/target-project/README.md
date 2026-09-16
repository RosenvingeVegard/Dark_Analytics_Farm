# Target project template

This folder is not a plugin — it's what you copy **into** the actual
Nortura Power BI / Fabric project repo (the one with the `.pbip`/`.Report`/
`.SemanticModel` folders) so the harness has something to enforce against.

## Setup

1. Copy `.claude-governance/`, `.claude/settings.json`, and `CLAUDE.md`
   into the root of the target project repo.
2. Edit `REPLACE-WITH-YOUR-ORG` in `.claude/settings.json` to your actual
   GitHub org/repo for `nortura-power-bi-agentic`.
3. Run the classification audit (see `data-governance-policy` skill in the
   `harness` plugin) and replace the example entries in both
   `.claude-governance/*.json` files with real workspace GUIDs, tiers, and
   dataset classifications. Get human sign-off on the proposed values
   before committing them — for anything personal/sensitive-personal, that
   should include Nortura's data protection contact.
4. Commit `.claude-governance/` and `.claude/settings.json` to the repo so
   the whole team (and the agent, every session) shares the same registry.
   `.claude/settings.local.json` (gitignored) is for personal overrides
   only — don't put registry data there.
5. `permissions.deny` in `settings.json` is a second, independent layer on
   top of the harness hook — it doesn't know about your registry, so keep
   it to hard-coded patterns you never want run regardless of registry
   state (tenant-admin commands, for example). It is not a substitute for
   keeping `.claude-governance/` accurate.
6. Fill in the "Repo layout" section at the bottom of `CLAUDE.md` once
   this is a real project — where the `.pbip` folders live, which
   workspace(s) it deploys to, the main branch name. Leave the rest of
   the file alone; it's meant to point at the skills, not duplicate them.

## Verifying it's wired up correctly

Don't rely on seeing a `SessionStart` message — as of Claude Code 2.1.0,
`SessionStart` hooks no longer print anything visible even when they
work, and there's a separate, documented gap where plugin-sourced
`SessionStart` hooks (this one included, especially over a local-path
marketplace) may not deliver their context to Claude at all. That hook
was always a nice-to-have status ping, not the actual enforcement, so
absence of a message proves nothing either way.

Test the part that actually matters instead — `policy-check.sh` on
`PreToolUse`:

1. Ask Claude to run a command that should get blocked, e.g. a `fab`
   command referencing a workspace GUID not in
   `.claude-governance/workspaces.json`. You should see it denied, with
   a reason naming the missing registry entry.
2. If `workspaces.json` still has its placeholder entry (see step 3
   above), *anything* touching a real workspace should be denied or
   asked about — that's the fail-closed default working as intended,
   not a bug.
3. Optionally, launch with `claude --debug` to confirm the hook is
   listed as matched and executed — this shows whether it fired at all,
   though not the content it returned.

If step 1 doesn't block the command, something's actually wrong — check
that `harness` shows as installed and enabled (`claude plugin list`)
before assuming the registry itself is the problem.
