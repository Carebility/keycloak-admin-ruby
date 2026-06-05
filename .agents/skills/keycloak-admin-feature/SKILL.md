---
name: keycloak-admin-feature
description: Implement a keycloak-admin gem feature end-to-end (plan → implement → spec → review), typically adding or extending Keycloak Admin REST API coverage. Accepts a free-text request, an instructions file, or a SKELETON plan from /cross-project-feature; supports --plan-only for plan generation without implementation. Five-phase workflow — (1) Discovery & Planning against the 5-edit resource pattern (client class, representation, two require_relative lines in lib/keycloak-admin.rb, RealmClient accessor) guided by the Keycloak Admin REST API reference, (2) Implementation per keycloak-admin-patterns, (3) Specs (unit specs stub TokenClient/RestClient; integration specs gate on ENV["GITHUB_ACTIONS"]), (4) Quality gates (bundle exec rspec) plus README/CHANGELOG/version updates, (5) Summary. Use when the user says "add support for X", "add a client for", "implement", or passes a plan file path. Do NOT use for bug fixes (use the keycloak-admin-bugfix skill).
---

# keycloak-admin Feature Implementation

## Inputs

- **Explicit format:**
  - `<feature request text> [--instructions <path>] [--plan-only]`
  - `<path-to-skeleton-or-plan-file> [--plan-only]` (when invoked from `/cross-project-feature` with a copied plan path)
- Required (one of):
  - free-text feature request/goal (everything before any flags)
  - OR an in-container plan file path (e.g. `/tmp/2026-05-07-plan-04-foo.md`) when invoked from `/cross-project-feature`
- Optional flags:
  - `--instructions <path>` flag pointing to a file containing implementation instructions
  - `--plan-only` suffix that runs Phase 1 (Discovery & Planning) and exits without implementing — used by `/cross-project-feature --review-concrete-plans` to produce concrete plans for human review
- If `--instructions` is provided, read that file first and treat its contents as additional requirements that must be incorporated into planning, implementation, and validation.
- Example (no file):
  - `Add support for the client-scopes admin endpoint`
- Example (with file):
  - `Add a client for organizations --instructions docs/features/organizations.md`

### Skeleton plan input mode (paradigm v2)

When invoked from `/cross-project-feature` (the coordinator-side cross-project
feature workflow), the input may point at a **skeleton plan** rather than
a full plan. A skeleton contains:

- Architecture intent (2–3 paragraphs about WHY the plan exists, what it
  changes, how it fits with sibling plans — no code)
- Frozen public interfaces / contracts that sibling plans depend on
- Advisory file inventory (paths + one-line purpose; not prescriptive)
- Acceptance criteria + quality gate command
- Integration points with sibling plans
- Out-of-scope notes
- Project-specific quirks the coordinator wants the agent to know

When you detect a skeleton plan (heuristic: the plan file's frontmatter or
early section says **`Plan-Generation Style: skeleton-delegated`** OR the
plan does NOT contain per-task verbatim code blocks), DO NOT transcribe.
Instead:

1. Run Phase 1 (Discovery & Planning) against the skeleton's intent + contracts
   + acceptance criteria, using the `keycloak-admin-patterns` skill for the
   gem's mechanics (the 5-edit resource pattern, base `Client` helpers,
   camelization rules, spec conventions). This repo has **no specialist
   subagents** — do the discovery and planning yourself with the patterns skill
   as your reference; never reference `@`-handles.
2. Honor every contract listed in the skeleton's "Public interfaces /
   contracts" section as FROZEN. Do not change names, signatures, or
   semantics there without flagging it explicitly in the PR. For this gem,
   contracts typically mean `RealmClient` accessor names, client class names,
   representation `attr_accessor` names, and the camelCase JSON keys read by
   `from_hash` that consumers (notably carebility-ruby) depend on.
3. Treat the skeleton's "File inventory" as advisory — add or remove files as
   the conventions in `keycloak-admin-patterns` dictate (a new resource almost
   always implies more files than a skeleton lists: a client, a representation,
   and a paired spec for each), but call out additions/removals in the PR.
4. Implement project-idiomatic Ruby that follows the existing patterns in
   `lib/keycloak-admin/client/` and `lib/keycloak-admin/representation/`. The
   recently-added client-scope feature (`ClientScopeClient` +
   `ClientScopeRepresentation`) is the precedent to mirror.
5. Run the skeleton's stated quality gate as the final check.

When invoked with a full plan (paradigm v1, or any free-text/instructions
invocation), continue the existing Phase 1 → Phase 2 → Phase 3 flow as
before. No backward-incompatible change to the v1 path.

> **About `/cross-project-feature`:** that slash command is **not** defined in
> this repo. It is a coordinator command that lives in a separate external
> project, which boots headless Claude Code sessions inside this repo and then
> dispatches into this skill with either a skeleton plan path or `--plan-only`
> packed into the invocation arguments. The notes above describe what the
> external coordinator passes in — not a local command.

### `--plan-only` mode

When `--plan-only` is present in the invocation arguments:

1. Run Phase 1 (Discovery & Planning) end-to-end against the skeleton or
   free-text feature request, exactly as you would in a normal invocation.
2. Write the concrete plan produced by Phase 1 to a file inside the container
   at `/tmp/$(basename "${ARGS_PLAN_PATH}" .md).concrete.md` (where
   `ARGS_PLAN_PATH` is the in-container plan path passed as input). If the
   input was free-text (no plan path), use `/tmp/plan.concrete.md`. The
   concrete plan must be executable step by step: each of the 5 edits spelled
   out (client class, representation, the two `require_relative` lines, the
   `RealmClient` accessor), the paired spec files, the exact endpoint URLs and
   payload shapes from the Keycloak Admin REST API reference, and the exact
   quality-gate commands.
3. Verify the file exists and is non-empty:

   ```bash
   test -s /tmp/$(basename "${ARGS_PLAN_PATH}" .md).concrete.md
   ```

4. **Stop after writing the concrete plan.** Do NOT proceed to Phase 2,
   Phase 3, or any implementation. Exit cleanly.

The coordinator's `bin/new-agent.sh --concrete-plan-out <local-path>` copies
`/tmp/<basename>.concrete.md` back to the coordinator workspace for human
review under the `--review-concrete-plans` flow.

When `--plan-only` is NOT present, continue normally through Phase 2 +
Phase 3 + subsequent phases.

## Phase 1: Discovery & Planning

0. **Detect input mode:**
   - If the input is free-text, run Phase 1 normally and produce an
     implementation plan.
   - If the input points at a plan file (e.g. `/tmp/<basename>.md`), read the
     file. Look for a `Plan-Generation Style:` line in the header.
     - If `Plan-Generation Style: skeleton-delegated` (or the file is short and
       lacks verbatim code blocks per task), run Phase 1 in skeleton-input mode
       per `## Inputs → Skeleton plan input mode (paradigm v2)`. Expand intent +
       contracts + advisory file inventory into a concrete plan; honor frozen
       contracts as constraints.
     - If the file looks like a full plan (has per-task verbatim code), use it
       as-is and skip the expansion.
   - Note whether `--plan-only` was passed in the invocation arguments.

1. **Resolve inputs before coding**:
   - Parse the input: feature request text = content before `--instructions`;
     optional instructions file path = value after `--instructions`.
   - Treat malformed flag usage (missing path, duplicate flags, empty feature
     text) as invalid input and ask for correction before proceeding.
   - If an instructions file path is present, read and summarize it; extract
     explicit requirements, constraints, and acceptance criteria. Ask for
     clarification only if the file is missing, unreadable, or contradictory.
   - Carry these requirements through every phase below.

2. **Explore the codebase** — read `lib/keycloak-admin/client/` and
   `lib/keycloak-admin/representation/` to find the closest existing resource
   to what is being asked. `ClientScopeClient` (`client/client_scope_client.rb`)
   and `ClientScopeRepresentation` (`representation/client_scope_representation.rb`)
   are the canonical precedent for adding a new top-level admin-API resource;
   read both alongside the base `Client` (`client/client.rb`) and the
   `RealmClient` registry (`client/realm_client.rb`). The
   `keycloak-admin-patterns` skill documents every mechanic these files rely on.

3. **Look up the endpoint contract.** This gem is a thin wrapper around the
   Keycloak Admin REST API, so the *shape* of every method (URL path segment,
   HTTP verb, request/response JSON) comes from the API itself, not from
   guesswork. Consult the Keycloak Admin REST API reference for the exact
   endpoint paths, payload fields, and response bodies:

   <https://www.keycloak.org/docs-api/latest/rest-api/index.html>

   Note the JSON the endpoint returns — those camelCase keys are what your
   representation's `from_hash` must read (deserialization is manual; see the
   patterns skill).

4. **Produce an implementation plan** that enumerates the **5-edit resource
   pattern** explicitly — forgetting the `require_relative` lines or the
   `RealmClient` accessor is the most common miss, so name all five up front:

   1. **Client class** — `lib/keycloak-admin/client/<thing>_client.rb`: a class
      under `module KeycloakAdmin` inheriting `Client`, with the realm guard
      and a `<thing>_url(id=nil)` helper. List the CRUD methods this resource
      needs (`create!`/`save`/`list`/`get`/`find_by_*`/`update`/`delete`).
   2. **Representation** — `lib/keycloak-admin/representation/<thing>_representation.rb`:
      a class under `module KeycloakAdmin` inheriting `Representation`, with
      snake_case `attr_accessor`s and a `self.from_hash` that reads the exact
      camelCase keys from the endpoint's response, defaulting collections to
      `[]`/`{}`.
   3. **require_relative (clients)** — add the client's `require_relative` line
      to the clients block in `lib/keycloak-admin.rb`.
   4. **require_relative (representations)** — add the representation's
      `require_relative` line to the representations block in
      `lib/keycloak-admin.rb`.
   5. **RealmClient accessor** — add a method to
      `lib/keycloak-admin/client/realm_client.rb`, e.g.
      `def <thing>; <Thing>Client.new(@configuration, self); end`.

   Plus the two paired spec files (Phase 3) and the README/CHANGELOG/version
   updates (Phase 4). For mechanics of each edit, defer to
   `keycloak-admin-patterns` rather than restating them here.

5. **`--plan-only` short-circuit:** If `--plan-only` was passed, write the
   concrete plan to `/tmp/$(basename "${ARGS_PLAN_PATH}" .md).concrete.md` (or
   `/tmp/plan.concrete.md` for free-text input), verify it with
   `test -s <path>`, and **exit cleanly** — do NOT proceed to Phase 2 or any
   implementation. If `--plan-only` was NOT passed, continue to Phase 2.

## Phase 2: Implementation

Implement the plan following `keycloak-admin-patterns` (read it now if you
have not). Prefer small, incremental diffs and mirror the client-scope
precedent rather than inventing new shapes. Key reminders the patterns skill
expands on:

- **Client class:** inherit `Client`, call `super(configuration)`, store
  `@realm_client`, and guard the constructor with
  `raise ArgumentError.new("realm must be defined") unless realm_client.name_defined?`.
  Build URLs from `@realm_client.realm_admin_url`. The Keycloak path segment is
  **hyphenated** (`client-scopes`) even though the Ruby helper is
  `client_scopes_url` — match the API's literal path, not the Ruby name.
- Wrap every HTTP call in `execute_http { RestClient::Resource.new(url, @configuration.rest_client_options).<verb>(...) }`,
  use the inherited `create_payload(rep)` for bodies and `headers` for auth, and
  `raise ArgumentError` on `nil` ids the way the precedent does.
- **Representation:** snake_case `attr_accessor`s; `self.from_hash` reads the
  literal camelCase keys Keycloak returns and **defaults collections to `[]`
  and hashes to `{}`** so callers never see nils; map nested objects to their
  own representation classes.
- Wire all 5 edits. Serialization auto-camelizes via `to_json`, but
  `from_hash` deserialization is manual — the keys must match the API exactly.

## Phase 3: Specs

Add one unit spec per new file and an integration spec only when the change is
CI-relevant. Unit specs are pure (no network); integration specs hit a real
Keycloak and only run in CI.

- **Client unit spec** (`spec/client/<thing>_client_spec.rb`): exercise the
  accessor (`KeycloakAdmin.realm(realm_name).<thing>`), assert it raises
  `ArgumentError` when the realm is nil, assert the exact collection vs item
  URL strings from `#<thing>_url`, and for CRUD stub the token + transport:

  ```ruby
  before(:each) do
    @client = KeycloakAdmin.realm(realm_name).client_scopes
    stub_token_client
    allow_any_instance_of(RestClient::Resource).to receive(:get).and_return '{"id":"...","name":"..."}'
  end
  ```

  `stub_token_client` (from `spec/spec_helper.rb`) stubs `TokenClient#get` so no
  real token is fetched; stubbing `RestClient::Resource` keeps the spec offline.
  Then assert the parsed representation's fields.
- **Representation unit spec** (`spec/representation/<thing>_representation_spec.rb`):
  call `described_class.from_hash({ ...camelCase string keys... })` and assert
  each attr, plus that nested objects are the right representation class (e.g.
  `be_a(KeycloakAdmin::ProtocolMapperRepresentation)`).
- **Integration spec** (`spec/integration/<thing>_spec.rb`, only if the feature
  needs live-Keycloak coverage): every example begins with
  `skip unless ENV["GITHUB_ACTIONS"]` and reconfigures to `http://localhost:8080/`,
  `use_service_account=false`, admin/admin, realm `dummy`. These run only in CI.

## Phase 4: Quality Gates

Run the gate:

```bash
bundle exec rspec
```

Then work the checklist before declaring done:

- [ ] Both `require_relative` lines added to `lib/keycloak-admin.rb` (the
      clients block AND the representations block).
- [ ] `RealmClient` accessor method added in
      `lib/keycloak-admin/client/realm_client.rb`.
- [ ] README updated: a bullet added to the **"Supported features"** list, plus
      a `### <usage>` subsection that states the **return type** (e.g. "Returns
      an instance of `KeycloakAdmin::ClientScopeRepresentation`") and a fenced
      `ruby` example rooted at
      `KeycloakAdmin.realm("a_realm").<accessor>.<method>(...)`.
- [ ] CHANGELOG entry added under a `## [X.Y.Z] - YYYY-MM-DD` header with `*`
      bullets describing the change.
- [ ] `lib/keycloak-admin/version.rb` bumped if this change is being released.
- [ ] New files `git add`-ed — the gemspec ships `spec.files = git ls-files`, so
      an untracked client/representation/spec silently fails to package.

**Gate-failure rule:** If a gate fails, fix the underlying issue and re-run the
full gate block — never skip a failing gate or proceed with a partial pass. If
you cannot resolve a failure, stop and report it as blocking rather than
shipping around it.

**Known issue (Ruby 3.4 in-container):** `bundle exec rspec` currently fails at
require time in the devcontainer with `LoadError: cannot load such file --
base64`, because `lib/keycloak-admin/configuration.rb` requires `base64`, which
left Ruby's default gems in 3.4 and is not declared as a gemspec dependency. CI
runs Ruby 3.2 where `base64` is still bundled, so **CI is the authoritative
gate.** Do not treat the in-container `base64` LoadError as a defect in your
change (it is a require-time `LoadError` raised before any examples run — distinct from an example/assertion failure in the rspec summary, which IS a real failure you must fix). The recommended permanent fix — adding `base64` to the gemspec runtime
deps — is a follow-up, not part of a docs-only or feature change unless your
task explicitly calls for it. (If deps are missing, install with
`bundle _4.0.13_ install`, not bare `bundle install` — see CLAUDE.md gotchas.)

## Phase 5: Summary

Provide a final summary:

- Files changed, grouped by the 5-edit pattern (client / representation /
  requires / accessor / specs) plus docs (README / CHANGELOG / version).
- The new public surface: `KeycloakAdmin.realm("...").<accessor>` and its
  methods, with return types.
- How to exercise it manually (a `ruby` snippet rooted at `KeycloakAdmin.realm`).
- Any follow-ups or known limitations (e.g. integration coverage deferred to
  CI, or the Ruby 3.4 `base64` known issue if it surfaced).
- For instruction-file runs, map each requirement to its implemented/tested
  outcome.
