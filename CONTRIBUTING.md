# Contributing

- Bump `version` in a plugin's `plugin.json` on every release, or updates
  won't reach existing installs (see the marketplace docs on version
  resolution).
- Before opening a PR: `claude plugin validate .` from the repo root, and
  test any change to `plugins/harness/scripts/*.sh` against the mock
  registries the way they were tested when first written — allow, ask,
  deny, and default-fallback cases for both workspace tier and data
  classification, plus the "no registry present" fail-closed case.
- Changes to `plugins/harness` or `plugins/process` should stay
  client-agnostic. If a change only makes sense for Nortura, it belongs in
  `plugins/nortura-design` or a new client-specific plugin instead.
- Pin the upstream `power-bi-agentic-development` marketplace to a
  released tag in any `settings.json` you ship (see
  `templates/target-project/.claude/settings.json`) rather than tracking
  `main`, since it has a stated weekly release cadence and has already had
  at least one breaking reorganization.
