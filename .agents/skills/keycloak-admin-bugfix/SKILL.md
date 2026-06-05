---
name: keycloak-admin-bugfix
description: Eight-phase bug-fix workflow for the keycloak-admin gem — (1) Investigation, (2) Reproduction as a failing unit spec (stub TokenClient + RestClient::Resource; never hit a live Keycloak), (3) Root cause analysis, (4) Fix, (5) Regression spec, (6) Security check (token/credential handling), (7) Validation via bundle exec rspec, (8) Summary with CHANGELOG entry. Use when the user says "fix this bug", "X endpoint returns the wrong thing", "deserialization is broken". Do NOT use for new API coverage (use the keycloak-admin-feature skill instead).
---

# keycloak-admin Bug Fix

A disciplined bug fix proves the bug exists with a failing spec *first*, then
fixes it, then proves it stays fixed. The hard rule for this gem: reproduction
and regression specs are **unit specs** that stub the token client and the HTTP
transport — never reach for a live Keycloak, because the failing path is almost
always URL construction or `from_hash` deserialization, both of which are pure
and fully testable offline.

## Phase 1: Investigation

- Reproduce the report mentally first: which accessor
  (`KeycloakAdmin.realm("...").<thing>`), which method, what input, what
  observed-vs-expected output.
- Locate the responsible layer using `keycloak-admin-patterns` as your map:
  - Wrong URL / 404 → the client's `<thing>_url` helper (check the hyphenated
    path segment and the collection/item id branch).
  - Wrong/`nil` attributes on the returned object → the representation's
    `from_hash` (a camelCase key mismatch leaves an attr silently nil).
  - Auth/401 → `Configuration` token retrieval (`use_service_account` branch,
    Basic header vs password body).
  - Exception text / error handling → base `Client#execute_http` / `#http_error`.
- Read the existing spec for that class to learn how it's already exercised.

## Phase 2: Reproduction (failing unit spec)

Write a spec that fails for the reported reason before touching any
implementation. Stub the token client and the transport so the spec is pure and
offline — this is the gem's standard unit-spec shape:

```ruby
before(:each) do
  @client = KeycloakAdmin.realm(realm_name).client_scopes
  stub_token_client
  allow_any_instance_of(RestClient::Resource).to receive(:get).and_return '{"id":"...","name":"..."}'
end
```

- `stub_token_client` (from `spec/spec_helper.rb`) stubs `TokenClient#get`, so no
  real token call is made.
- Stubbing `RestClient::Resource` keeps the spec from hitting the network; feed
  it the exact JSON body (or `""`) that triggers the bug.
- For a deserialization bug, the cleaner reproduction is often a representation
  spec: `described_class.from_hash({ ...the camelCase keys from the bad response... })`
  asserting the attr the user says is wrong.
- Confirm the spec **fails** for the expected reason. A spec that passes before
  the fix proves nothing.

**Known issue — in-container rspec may not load at all:** on Ruby 3.4 devcontainers, `bundle exec rspec` can die at require time with `LoadError: cannot load such file -- base64` before any example runs. To do the red/green loop locally, install the gem into the bundle first (`gem install base64` or add it temporarily to the Gemfile of your working tree — do NOT commit that change), then re-run. If you cannot get rspec to load locally, push the branch and confirm the red→green transition in CI (Ruby 3.2), noting this in your summary.

## Phase 3: Root Cause Analysis

State the actual cause in one or two sentences — not the symptom. Common roots
in this gem:

- A `from_hash` key that doesn't match Keycloak's literal camelCase JSON (attr
  stays nil), or a collection not defaulted to `[]`/`{}`.
- A `<thing>_url` segment that's wrong (snake_case instead of hyphenated, or the
  id branch building the collection URL).
- A `use_service_account` branch picking the wrong grant/header.
- A `create_payload` assumption (nil vs Array vs object).

Confirm the diagnosis explains the failing spec exactly before fixing.

## Phase 4: Fix

Apply the smallest change that addresses the root cause, following
`keycloak-admin-patterns`. Don't refactor surrounding code or rename public
surface (accessor names, representation attrs, camelCase keys) as part of a bug
fix — those are contracts consumers like carebility-ruby depend on. If the right
fix changes a contract, flag it explicitly rather than slipping it in.

## Phase 5: Regression Spec

Make the Phase 2 spec pass, and keep it as the regression guard. If the bug had
adjacent cases (e.g. the empty-collection vs populated-collection paths, or the
id vs no-id URL branch), add assertions for those too so the fix can't regress
partially. Re-run to confirm green.

## Phase 6: Security Check

A bug fix can quietly introduce a leak. Verify the change does not:

- Put `client_secret`, `password`, or a bearer token into `logger` output or
  into an exception message (`http_error` already echoes the response body —
  don't widen what it includes).
- Disable or weaken TLS verification in `rest_client_options`.
- Add a real credential to a spec/fixture. Integration creds are CI-local
  `admin`/`admin` only.

If the fix touches auth/token flow, escalate to the
`keycloak-admin-security-review` skill before merging.

## Phase 7: Validation

Run the gate:

```bash
bundle exec rspec
```

**Gate-failure rule:** If a gate fails, fix the underlying issue and re-run the
full gate block — never skip a failing gate or proceed with a partial pass. If
you cannot resolve a failure, stop and report it as blocking rather than
shipping around it.

**Known issue (Ruby 3.4 in-container):** `bundle exec rspec` currently fails at
require time in the devcontainer with `LoadError: cannot load such file --
base64`, because `lib/keycloak-admin/configuration.rb` requires `base64`, which
left Ruby's default gems in 3.4 and is not declared as a gemspec dependency. CI
runs Ruby 3.2 where `base64` is still bundled, so **CI is the authoritative
gate.** Do not mistake this LoadError for a regression from your fix (it is a require-time `LoadError` raised before any examples run — distinct from an example/assertion failure in the rspec summary, which IS a real failure you must fix). The
recommended permanent fix is adding `base64` to the gemspec runtime deps as a
follow-up. (If deps are missing, install with `bundle _4.0.13_ install`, not
bare `bundle install` — see CLAUDE.md gotchas.)

## Phase 8: Summary

Provide a final summary:

- Root cause in one or two sentences and the file/line fixed.
- The regression spec(s) added and what they guard.
- CHANGELOG entry: add a `* ` bullet under a `## [X.Y.Z] - YYYY-MM-DD` header
  describing the fix (credit a reporter with `thanks to @user` if relevant).
- Security check result (clean, or what was tightened).
- Any follow-ups (e.g. the Ruby 3.4 `base64` known issue if it surfaced).
