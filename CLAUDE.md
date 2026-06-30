# keycloak-admin-ruby

## Purpose

`keycloak-admin-ruby` is a **plain Ruby gem (not a Rails app)** that wraps the
Keycloak Admin REST API. You configure it once, ask for a realm, and call
accessor methods that build URLs, make authenticated HTTP calls, and deserialize
the JSON responses into Ruby *representation* objects.

It is Carebility's **hard fork** of `looorent/keycloak-admin-ruby`. Upstream is
**never merged** — treat this repo as the sole source of truth; do not add an
`upstream` remote, rebase from it, or defer work to a non-existent upstream sync.

The primary consumer is **carebility-ruby**, which depends on this gem via a
**Gemfile git ref pinned to `main`** (not a published RubyGems version). A merge
to `main` is effectively a release to carebility-ruby on its next bundle update,
so the public surface — `RealmClient` accessor names, representation
`attr_accessor` names, and the camelCase JSON keys `from_hash` reads — is a
contract that must not change casually.

For a fuller orientation, see the `repo-overview` skill. For deep conventions,
see `keycloak-admin-patterns`.

## Commands

```bash
bundle _4.0.13_ install   # NOT bare bundle install — see gotchas
bundle exec rspec         # integration specs auto-skip outside CI; see gotchas for Ruby 3.4 known issue
```

## Architecture

A request is a URL string + a `RestClient` call; the JSON response is
deserialized into a representation object. Three layers plus a registry and a
configuration singleton:

| Layer | Directory | Base class | Role |
|---|---|---|---|
| Client | `lib/keycloak-admin/client/` | `KeycloakAdmin::Client` | URL builder + HTTP verbs (CRUD). One per endpoint family. |
| Representation | `lib/keycloak-admin/representation/` | `Representation` (top-level, NOT namespaced) | Plain data object; snake_case attrs ⇄ camelCase JSON. |
| Resource | `lib/keycloak-admin/resource/` | `BaseRoleContainingResource` | A single fetched entity exposing id-scoped sub-clients. Used only where an entity owns child collections. |

- **`RealmClient` registry** (`lib/keycloak-admin/client/realm_client.rb`): the
  root returned by `KeycloakAdmin.realm(realm_name)`. Every endpoint family is an
  accessor method here (`clients`, `groups`, `roles`, `users`, `organizations`,
  `client_scopes`, …); a new resource is unreachable until its accessor is wired
  in.
- **`Configuration` auth modes** (`lib/keycloak-admin/configuration.rb`):
  `use_service_account=true` (default) uses `grant_type=client_credentials` with
  an HTTP Basic `Base64(client_id:client_secret)` header;
  `use_service_account=false` uses `grant_type=password` with a
  username/password body. `#body_for_token_retrieval` and
  `#headers_for_token_retrieval` branch on it. Defaults: `client_id="admin-cli"`,
  `use_service_account=true`, `logger=Logger.new(STDOUT)`; `server_url` is
  required.

## Conventions

- **5-edit pattern for a new resource:** (1) client class under `client/`
  inheriting `Client` with the realm guard and a `<thing>_url(id=nil)` helper,
  (2) representation under `representation/` inheriting `Representation` with
  snake_case `attr_accessor`s and a manual `from_hash`, (3) + (4) the two
  `require_relative` lines in `lib/keycloak-admin.rb` (clients block AND
  representations block), (5) the `RealmClient` accessor — plus paired client and
  representation specs. Mirror the `ClientScopeClient` / `ClientScopeRepresentation`
  precedent. Full mechanics: `keycloak-admin-patterns`.
- **Camelization:** `to_json` auto-camelizes snake_case attrs (serialization is
  automatic), but `from_hash` deserialization is **manual** — read the exact
  camelCase string keys Keycloak returns, or the attr silently stays nil. Default
  collections to `[]`/`{}`.
- **Hyphenated URLs:** Keycloak path segments are hyphenated (`client-scopes`)
  even though the Ruby helper is `client_scopes_url`. Match the API's literal
  path.
- **Spec stubbing:** unit specs are offline — `stub_token_client` stubs
  `TokenClient#get`, and `allow_any_instance_of(RestClient::Resource).to
  receive(:get/:post/...)` stubs the transport. Integration specs
  (`spec/integration/`) start with `skip unless ENV["GITHUB_ACTIONS"]` and run
  only in CI.
- **Documentation pattern:** a new feature adds a bullet to the README
  **"Supported features"** list plus a `### <usage>` subsection (return type +
  a `ruby` example rooted at `KeycloakAdmin.realm("a_realm").<accessor>.<method>`),
  and a CHANGELOG entry under `## [X.Y.Z] - YYYY-MM-DD` with `*` bullets.

## Gotchas

- **CI/branch is `main`, not `master`/`dev`.** Unlike most Carebility repos there
  are no environment branches; CI triggers on push/PR to `main`, and
  carebility-ruby pins its Gemfile git ref to `main`.
- **Hard fork — upstream is never merged.** Don't add an `upstream` remote or
  defer work to an upstream sync; this repo is the source of truth.
- **A new resource is 5 coordinated edits** (client, representation, two
  `require_relative` lines, `RealmClient` accessor) + 2 specs. The common miss is
  forgetting a `require_relative` or the accessor — both fail silently because
  specs that import the class directly still pass.
- **`spec.files = git ls-files`** in the gemspec → new files must be `git add`-ed
  or they won't be packaged and shipped to consumers, even though local specs
  pass.
- **Serialization auto-camelizes; deserialization does not.** `from_hash` must
  read literal camelCase keys matching Keycloak's exact JSON. Note
  `ProtocolMapperRepresentation` keeps `protocolMapper` as a literal attr name —
  an existing inconsistency; match what a representation already does rather than
  "fixing" it.
- **URL path segments are hyphenated** (`client-scopes`) regardless of the Ruby
  method name.
- **Integration specs only run when `ENV["GITHUB_ACTIONS"]` is set.** Unit specs
  stub `TokenClient` + `RestClient::Resource` and never touch the network.
- **`Representation` base class is top-level (global namespace);** concrete
  representations live under `module KeycloakAdmin`. In specs the base is
  `Representation`; concrete classes are `KeycloakAdmin::ClientScopeRepresentation`.
- **Bundler pin vs Ruby 3.4 — use `bundle _4.0.13_ install`.** The devcontainer
  runs Ruby 3.4.x. `Gemfile.lock` says `BUNDLED WITH 2.1.4`; a bare
  `bundle install` auto-installs bundler 2.1.4, which is incompatible with Ruby
  3.4 (it references `DidYouMean::SPELL_CHECKERS`, removed in 3.4) and crashes.
  Invoking a newer bundler explicitly (`bundle _4.0.13_ install`) bypasses the
  lockfile's bundler pin (or whatever bundler version `bundle --version` reports — the point is to bypass the lockfile's 2.1.4 pin).
- **`base64` LoadError on Ruby 3.4 (KNOWN ISSUE).** `bundle exec rspec` currently
  fails at require time in the devcontainer with `LoadError: cannot load such
  file -- base64`: `lib/keycloak-admin/configuration.rb:1` requires `base64`,
  which left Ruby's default gems in 3.4 and is **not** declared as a gemspec
  dependency. CI runs Ruby 3.2, where `base64` is still bundled, so the gate
  passes there — **CI is the authoritative quality gate.** Recommended permanent
  fix (a follow-up, not part of a docs-only change): add `base64` to the gemspec
  runtime dependencies.
