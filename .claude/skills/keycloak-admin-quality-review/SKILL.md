---
name: keycloak-admin-quality-review
description: Run the gem's quality gates and produce a structured report — Phase 1 gates (bundle exec rspec; integration specs auto-skip outside CI), Phase 2 analysis (5-edit completeness for new resources, README/CHANGELOG/version hygiene, git-tracked files vs spec.files), Phase 3 report, Phase 4 follow-up task creation. Use when the user says "quality review", "run the gates", "is this ready for PR". Do NOT use for security-focused audits (use the keycloak-admin-security-review skill).
---

# keycloak-admin Quality Review

A quality review answers one question: is this branch ready for a PR? Run the
gate, then check the things the gate can't see — the 5-edit completeness of any
new resource and the documentation/packaging hygiene that keeps the gem
shippable.

## Phase 1: Run Quality Gates

**Install deps first if they're missing — but NOT with bare `bundle install`.**
The repo's `Gemfile.lock` says `BUNDLED WITH 2.1.4`, and a bare `bundle install`
auto-installs bundler 2.1.4, which is incompatible with Ruby 3.4 in the
devcontainer (it references `DidYouMean::SPELL_CHECKERS`, removed in 3.4, and
crashes). Use a newer bundler explicitly to bypass the lockfile's bundler pin:

```bash
bundle _4.0.13_ install
```

(or whatever bundler version `bundle --version` reports — the point is to bypass the lockfile's 2.1.4 pin)

Then run the gate:

```bash
bundle exec rspec
```

Integration specs (`spec/integration/`) begin with `skip unless ENV["GITHUB_ACTIONS"]`,
so they auto-skip locally and only execute in CI against the real Keycloak
service container — skips here are expected, not failures.

**KNOWN ISSUE (Ruby 3.4 in-container):** `bundle exec rspec` currently fails at
require time with `LoadError: cannot load such file -- base64`.
`lib/keycloak-admin/configuration.rb` requires `base64`, which left Ruby's
default gems in 3.4 and is **not** declared as a gemspec dependency. CI runs
Ruby 3.2, where `base64` is still bundled, so the gate passes there. **CI on Ruby
3.2 is the authoritative quality gate.** Treat an in-container `base64` LoadError
as the known environment issue, not as a failure of the branch under review. The
recommended permanent fix — adding `base64` to the gemspec runtime deps — is a
follow-up item to record in Phase 4, not something to silently fold into an
unrelated review.

**Gate-failure rule:** for any *real* failure (a spec assertion, not the base64
LoadError), fix the underlying issue and re-run the full gate — never skip a
failing gate or pass a partial run. If you cannot resolve it, report it as
blocking.

## Phase 2: Analyze Results

Check the things `rspec` doesn't:

**5-edit completeness (for any new resource on the branch).** For each new
admin-API resource, confirm all five edits plus both specs landed — a missing
`require_relative` or accessor passes local specs that import the class directly
but breaks real `KeycloakAdmin.realm("...").<thing>` usage:

- [ ] Client class under `lib/keycloak-admin/client/`.
- [ ] Representation under `lib/keycloak-admin/representation/`.
- [ ] `require_relative` for the client in the clients block of
      `lib/keycloak-admin.rb`.
- [ ] `require_relative` for the representation in the representations block of
      `lib/keycloak-admin.rb`.
- [ ] `RealmClient` accessor method in
      `lib/keycloak-admin/client/realm_client.rb`.
- [ ] Client spec (`spec/client/<thing>_client_spec.rb`) AND representation spec
      (`spec/representation/<thing>_representation_spec.rb`).

**Documentation hygiene.**

- [ ] README has a bullet in the **"Supported features"** list for any new
      operation, plus a `### <usage>` subsection stating the return type and a
      `ruby` example rooted at `KeycloakAdmin.realm("a_realm").<accessor>.<method>`.
- [ ] CHANGELOG has an entry under a `## [X.Y.Z] - YYYY-MM-DD` header with `*`
      bullets for the change.
- [ ] `lib/keycloak-admin/version.rb` bumped if this is a release.

**Packaging hygiene.**

- [ ] All new files are git-tracked. The gemspec ships `spec.files = git ls-files`,
      so an untracked file is silently excluded from the published gem even
      though specs pass. Verify with `git status` / `git ls-files`.
- [ ] No assumption that upstream (`looorent/keycloak-admin-ruby`) will be
      merged. This is a **hard fork** — upstream is never pulled, so don't defer
      a fix or a doc to "the next upstream sync."

## Phase 3: Report

Produce a structured report:

- **Gate result:** pass / fail, with the `rspec` summary line (examples, failures,
  pending/skipped). If the run hit the base64 LoadError, state that explicitly
  and note CI/Ruby 3.2 is authoritative.
- **5-edit completeness:** per-resource checklist result, naming any missing edit.
- **Documentation & packaging:** README / CHANGELOG / version / git-tracking
  results.
- **Verdict:** ready for PR, or blocked with the specific gaps to close.

## Phase 4: Follow-up Task Creation

Record any unresolved items as follow-ups so they aren't lost (a Linear issue or a tracked TODO, matching the keycloak-theme suite's convention):

- The `base64` gemspec dependency fix, if the in-container LoadError surfaced and
  isn't already tracked.
- Any missing 5-edit element, doc gap, or untracked file that the branch owner
  should close before merge.
- Note the recently-added client-scope feature is not yet documented in the
  README (a pre-existing doc gap) if a review touches that area.
