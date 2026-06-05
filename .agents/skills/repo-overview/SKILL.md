---
name: repo-overview
description: Orientation tour of the keycloak-admin-ruby repo — a hard fork of looorent/keycloak-admin-ruby (upstream is NEVER merged), a plain Ruby gem (not Rails) wrapping the Keycloak Admin REST API in client/representation/resource layers rooted at KeycloakAdmin.realm(); consumed by carebility-ruby via a Gemfile git ref on main; single-branch repo (main) with CI running rspec against a real Keycloak 25.0.1 service container. Use when the user says "repo overview", "codebase tour", "where is", "how does this gem work", or at the start of a session in an unfamiliar area.
---

# keycloak-admin-ruby Repo Overview

`keycloak-admin-ruby` is a **plain Ruby gem (not a Rails app)** that wraps the
Keycloak Admin REST API. You configure it once, ask for a realm, and call
accessor methods that build URLs, make authenticated HTTP calls, and deserialize
the JSON into Ruby objects. It is Carebility's **hard fork** of
`looorent/keycloak-admin-ruby` — see the hard-fork policy below.

## HARD-FORK POLICY (read first)

This repo is a **hard fork**. Upstream `looorent/keycloak-admin-ruby` is
**NEVER merged** back in. Do not:

- Add `git remote add upstream ...` and pull/rebase from it.
- Defer a fix or a doc to "the next upstream sync" — there is none.
- Assume an upstream PR will land here, or that our changes flow upstream.

Treat the code in this repo as the sole source of truth. New work is authored
directly here and shipped from `main`.

## Layer map

A request is built as a URL string + a `RestClient` call, then the JSON response
is deserialized into a *representation* object. Three layers:

| Layer | Directory | Base class | Role |
|---|---|---|---|
| Client | `lib/keycloak-admin/client/` | `KeycloakAdmin::Client` | URL builder + HTTP verbs (CRUD). One client per Keycloak admin endpoint family. |
| Representation | `lib/keycloak-admin/representation/` | `Representation` (top-level, not namespaced) | Plain data object; snake_case Ruby attrs ⇄ camelCase JSON. |
| Resource | `lib/keycloak-admin/resource/` | `BaseRoleContainingResource` | A single fetched entity (a user/group) exposing id-scoped sub-clients (e.g. role mappings). Used only where an entity owns child collections. |

Other key files: `lib/keycloak-admin.rb` (entry points + the require manifest),
`lib/keycloak-admin/configuration.rb` (config + auth), `lib/keycloak-admin/version.rb`,
`keycloak-admin.gemspec`, `spec/spec_helper.rb`, and `.github/workflows/ci.yml`.

## Entry-point walkthrough

```ruby
KeycloakAdmin.configure do |config|
  config.server_url           = "https://keycloak.example.com"
  config.client_secret        = "..."
  config.use_service_account  = true   # default
end

realm = KeycloakAdmin.realm("a_realm")  # => RealmClient
realm.client_scopes.list                # => [KeycloakAdmin::ClientScopeRepresentation, ...]
```

- **`KeycloakAdmin.configure { |config| ... }`** yields the singleton
  `Configuration` (server URL, credentials, auth mode, logger, rest-client
  options).
- **`KeycloakAdmin.realm(realm_name)`** returns a `RealmClient` — the root from
  which every other client hangs.
- **`RealmClient` is the registry:** each endpoint family is an instance method
  (`clients`, `groups`, `roles`, `users`, `organizations`, `identity_providers`,
  `client_scopes`, `authz_scopes(...)`, …). Each returns a client whose methods
  build URLs from `realm_admin_url` and parse responses via
  `<Thing>Representation.from_hash`.

## Consumer relationship

The primary consumer is **carebility-ruby**, which depends on this gem via a
**Gemfile git ref pinned to `main`** (not a published RubyGems version). That
means: a merge to `main` is effectively a release to carebility-ruby on its next
bundle update, and the **public surface is a contract** — accessor names,
representation `attr_accessor` names, and the camelCase JSON keys `from_hash`
reads must not change casually, because carebility-ruby relies on them.

## Branch & CI model

- **Single branch: `main`.** Unlike most Carebility repos, there are no
  environment branches (`dev`/`staging`/`prod`); CI triggers on push/PR to
  `main`.
- **CI (`.github/workflows/ci.yml`, Ruby 3.2)** spins up a **real Keycloak 25.0.1
  service container** (`tillawy/keycloak-github-actions:25.0.1`, admin/admin,
  port 8080), then a pre-test step obtains an admin token and `curl`-creates
  realm `dummy` + client `dummy-client`. Tests run `bundle exec rspec` with
  `GITHUB_ACTIONS: true`, which is the env gate that **enables the integration
  specs** (`spec/integration/`). Unit specs run everywhere; integration specs run
  only in CI.

## Change-type → skill pointer

| You want to… | Use this skill |
|---|---|
| Add or extend Admin REST API coverage (a new client/resource) | `keycloak-admin-feature` |
| Fix a bug (wrong URL, bad deserialization, auth failure) | `keycloak-admin-bugfix` |
| Look up a convention (5-edit pattern, `from_hash`, `RealmClient`, camelization, spec stubs, auth modes) | `keycloak-admin-patterns` |
| Run the gates and check PR-readiness | `keycloak-admin-quality-review` |
| Audit credential/token/transport security | `keycloak-admin-security-review` |
