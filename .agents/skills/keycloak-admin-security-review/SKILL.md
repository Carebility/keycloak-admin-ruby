---
name: keycloak-admin-security-review
description: Security review for the Keycloak Admin API client gem — Phase 1 scope, Phase 2 credential audit (client_secret/password handling, Basic-auth header construction, no credentials in logger output or error messages raised by http_error), Phase 3 transport audit (rest_client_options TLS verification, server_url scheme), Phase 4 spec hygiene (no real secrets in specs/fixtures; integration creds are CI-local admin/admin only), Phase 5 findings report. Use when the user says "security review", "audit the gem", or before merging auth/token-flow changes. Do NOT use for general quality gates (use the keycloak-admin-quality-review skill).
---

# keycloak-admin Security Review

This gem is an authenticated client for the Keycloak Admin REST API: it holds a
`client_secret` (or username/password), exchanges them for a bearer token, and
sends that token on every request. The security surface is therefore credential
and token handling, transport security, and making sure none of it leaks into
logs, error messages, or specs. Review against these five phases.

## Phase 1: Scope

Determine what the review covers:

- A targeted review of a branch's auth/token-flow changes (the common case
  before merging anything that touches `Configuration`, token retrieval, or
  `Client#http_error`), or
- A full-gem audit of the credential/transport surface.

List the files in scope. The recurring high-value targets are
`lib/keycloak-admin/configuration.rb`, `lib/keycloak-admin/client/client.rb`
(`http_error`), the token client, and `spec/` fixtures.

## Phase 2: Credential Audit

Inspect `lib/keycloak-admin/configuration.rb`:

- **Basic-auth header construction:** the service-account mode
  (`use_service_account=true`) builds the token-request header as HTTP Basic
  `Base64(client_id:client_secret)`. Confirm the secret is only assembled for the
  token request and is not stored, logged, or echoed elsewhere. `Base64` is
  encoding, not encryption — treat the encoded value as a live credential.
- **Password-grant body:** the `use_service_account=false` mode puts
  `username`/`password`/`client_id`/`client_secret` into the token-request body.
  Confirm that body is never written to `logger` and never included in an
  exception message.
- **No secret in `logger` output:** the configured `logger` defaults to
  `Logger.new(STDOUT)`. Verify no code path logs the secret, password, the
  Basic header, or the bearer token at any level.

Inspect `lib/keycloak-admin/client/client.rb`:

- **`http_error` message:** it raises
  `"Keycloak: The request failed with response code #{code} and message: #{body}"`.
  Check whether `body` (the raw Keycloak error response) can carry sensitive
  data, and confirm the request's own `Authorization: Bearer ...` header or any
  credential is **not** interpolated into the raised message. Flag any change
  that would widen this message to include request headers or the token.

## Phase 3: Transport Audit

- **TLS verification:** `rest_client_options` is passed straight into
  `RestClient::Resource`. Confirm nothing in the gem or its defaults disables
  certificate verification (e.g. `verify_ssl: false`,
  `OpenSSL::SSL::VERIFY_NONE`). If a branch adds such an option, flag it — it
  must be opt-in by the consumer and documented, never a default.
- **`server_url` scheme:** the gem talks to whatever `server_url` is configured.
  Note that production usage must be `https://`; the only sanctioned `http://`
  target is the CI integration `http://localhost:8080/` Keycloak service
  container. Flag any default or doc that steers production toward `http://`.

## Phase 4: Spec Hygiene

- **No real secrets in specs/fixtures.** Unit specs use the fake
  `server_url = "http://auth.service.io/auth"` and stub the token client — there
  should be no real client secret, password, or token literal anywhere under
  `spec/`.
- **Integration credentials are CI-local only.** `spec/integration/` examples
  reconfigure to `http://localhost:8080/`, `use_service_account=false`,
  `admin`/`admin` against realm `dummy`. Those `admin`/`admin` values are the
  throwaway credentials of the ephemeral CI Keycloak container and are
  acceptable; confirm no *real* environment credential has crept in beside them.

## Phase 5: Findings Report

Produce a structured findings report:

- **Scope:** files reviewed and whether targeted or full-gem.
- **Findings:** each with severity, the file/line, what leaks or weakens
  security, and the concrete fix. Use the categories above (credential handling,
  `http_error` leakage, TLS/transport, spec hygiene).
- **Clean areas:** briefly note what was checked and found sound, so the review
  is auditable.
- **Verdict:** safe to merge, or blocked with the specific items to fix first.
  For auth/token-flow changes, an unresolved credential-leak or TLS finding is
  blocking.
