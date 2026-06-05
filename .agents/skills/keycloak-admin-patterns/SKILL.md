---
name: keycloak-admin-patterns
description: Conventions for the keycloak-admin gem — the 5-edit pattern for new Admin REST API resources (client class inheriting Client with realm guard + <thing>_url(id=nil) helper, representation with snake_case attr_accessors + manual camelCase from_hash, two require_relative lines in lib/keycloak-admin.rb, RealmClient accessor, paired specs); execute_http/create_payload/headers inherited helpers; camelization gotchas (to_json auto-camelizes, from_hash reads literal camelCase keys); hyphenated URL segments (client-scopes); unit vs integration spec split (ENV["GITHUB_ACTIONS"] gate); configuration/auth modes (use_service_account client_credentials vs password grant). Trigger on phrases like "client class", "representation", "from_hash", "RealmClient", "camelCase", or when editing files under lib/keycloak-admin/ or spec/.
---

# keycloak-admin Patterns

This gem is a thin, three-layer wrapper around the Keycloak Admin REST API. A
request is a URL string plus a `RestClient` call; the JSON response is
deserialized into a *representation* object. Understanding the three layers and
the 5-edit pattern is most of the job.

| Layer | Dir | Base class | Role |
|---|---|---|---|
| Client | `lib/keycloak-admin/client/` | `KeycloakAdmin::Client` | URL builder + HTTP verbs (CRUD). One per Keycloak admin endpoint family. |
| Representation | `lib/keycloak-admin/representation/` | `Representation` (top-level, NOT namespaced) | Plain data object; snake_case attrs ⇄ camelCase JSON. |
| Resource | `lib/keycloak-admin/resource/` | `BaseRoleContainingResource` | A single fetched entity (a user/group) that exposes id-scoped sub-clients (role mappings). Only used where an entity has child collections. |

Entry points all live in `lib/keycloak-admin.rb`: `KeycloakAdmin.configure { |c| ... }`
yields the singleton `Configuration`; `KeycloakAdmin.realm(realm_name)` returns a
`RealmClient`, the root from which every other client hangs.

## Adding a resource end-to-end

The recently-added **client scope** feature is the canonical template. Adding a
new top-level admin-API resource is **5 coordinated edits** plus 2 specs.
Forgetting a `require_relative` line or the `RealmClient` accessor is the common
miss — they fail silently until something tries to load or call the new class.

### Edit 1 — Client class (`lib/keycloak-admin/client/<thing>_client.rb`)

```ruby
module KeycloakAdmin
  class ClientScopeClient < Client
    def initialize(configuration, realm_client)
      super(configuration)
      raise ArgumentError.new("realm must be defined") unless realm_client.name_defined?
      @realm_client = realm_client
    end

    def list
      execute_http do
        RestClient::Resource.new(client_scopes_url, @configuration.rest_client_options).get(headers)
      end.body.then { |b| JSON.parse(b).map { |h| ClientScopeRepresentation.from_hash(h) } }
    end

    def get(client_scope_id)
      raise ArgumentError.new("client scope id must be defined") if client_scope_id.nil?
      response = execute_http do
        RestClient::Resource.new(client_scopes_url(client_scope_id), @configuration.rest_client_options).get(headers)
      end
      ClientScopeRepresentation.from_hash(JSON.parse(response.body))
    end

    def save(client_scope_representation)
      execute_http do
        RestClient::Resource.new(client_scopes_url, @configuration.rest_client_options)
          .post(create_payload(client_scope_representation), headers)
      end
    end

    def client_scopes_url(client_scope_id=nil)
      if client_scope_id
        "#{@realm_client.realm_admin_url}/client-scopes/#{client_scope_id}"
      else
        "#{@realm_client.realm_admin_url}/client-scopes"
      end
    end
  end
end
```

Conventions baked into the precedent:

- Inherit `Client`, call `super(configuration)`, store `@realm_client`, and
  guard the constructor with the **literal** message
  `raise ArgumentError.new("realm must be defined") unless realm_client.name_defined?`.
- Build URLs from `@realm_client.realm_admin_url`
  (= `#{server_url}/admin/realms/#{realm_name}`). The Keycloak path segment is
  **hyphenated** (`client-scopes`) even though the Ruby method is
  `client_scopes_url` — match the API's literal path.
- A single **`<thing>_url(id=nil)` helper** returns the collection URL when `id`
  is nil and the item URL otherwise — this collection/item duality is the
  convention; don't write two separate URL methods.
- Every HTTP call is wrapped:
  `execute_http { RestClient::Resource.new(url, @configuration.rest_client_options).<verb>(...) }`.
- `create!` typically POSTs then re-fetches/finds the created entity to return a
  representation; this gem's `save` returns the raw response. `list`/`get` parse
  JSON via `<Thing>Representation.from_hash`. Methods that take an id
  `raise ArgumentError.new("... must be defined") if id.nil?`; `delete` returns
  `true`.
- For the find-by-attribute shape, see `find_by_name` in `lib/keycloak-admin/client/client_scope_client.rb` — list the collection, then select on the attribute.

### Edit 2 — Representation (`lib/keycloak-admin/representation/<thing>_representation.rb`)

```ruby
module KeycloakAdmin
  class ClientScopeRepresentation < Representation
    attr_accessor :id, :name, :description, :protocol, :attributes, :protocol_mappers

    def self.from_hash(hash)
      r = new
      r.id          = hash["id"]
      r.name        = hash["name"]
      r.description = hash["description"]
      r.protocol    = hash["protocol"]
      r.attributes       = hash["attributes"] || {}
      r.protocol_mappers = (hash["protocolMappers"] || []).map { |m| ProtocolMapperRepresentation.from_hash(m) }
      r
    end
  end
end
```

- Inherit `Representation` (top-level/global), but the concrete class IS under
  `module KeycloakAdmin`.
- `attr_accessor`s are **snake_case**; the mandatory `self.from_hash(hash)` reads
  **literal camelCase string keys** as Keycloak returns them
  (`hash["protocolMappers"]`).
- **Default collections to `[]` and hashes to `{}`** so callers never see nils.
  Map nested objects to their own representation classes.

### Edit 3 & 4 — require manifest (`lib/keycloak-admin.rb`)

Add BOTH `require_relative` lines. The file requires clients first as a block,
then representations, then resources. Add the client line to the clients block
and the representation line to the representations block. Order matters only for
cross-references resolved at load time, so keep a new class after anything it
references.

### Edit 5 — RealmClient accessor (`lib/keycloak-admin/client/realm_client.rb`)

```ruby
def client_scopes
  ClientScopeClient.new(@configuration, self)
end
```

`RealmClient` is the registry — every endpoint family is exposed here
(`clients`, `groups`, `roles`, `users`, `organizations`, `identity_providers`,
`authz_scopes(client_id, resource_id=nil)`, …). A new resource is unreachable
until its accessor is wired in.

## Base Client helpers

Inherited by every client (`lib/keycloak-admin/client/client.rb`):

- **`current_token`** — memoized; fetches the access token via the realm's
  `TokenClient` so repeated calls reuse one token.
- **`headers`** → `{ Authorization: "Bearer #{...}", content_type: :json, accept: :json }`.
- **`execute_http { ... }`** — rescues `RestClient::Exceptions::Timeout`
  (re-raised) and `RestClient::ExceptionWithResponse`, routing the latter to
  `http_error`, which raises
  `"Keycloak: The request failed with response code #{code} and message: #{body}"`.
- **`created_id(response)`** — asserts the response is `Net::HTTPCreated` (201)
  then parses the trailing id out of the `Location` header. Use this after a POST
  that returns 201 + Location instead of a body.
- **`create_payload(value)`** — `nil` → `""`, `Array` → JSON array string, else
  `value.to_json`. Use it for every request body so the nil/array/object cases
  are handled uniformly.

## Representation & camelization

- `Representation#as_json` reflects over instance vars, strips the leading `@`,
  and recursively converts nested `Representation`/`Array`/`Hash` values.
- `Representation#to_json` → `deep_camelize_keys(as_json).to_json`, so snake_case
  Ruby attrs are serialized as camelCase JSON keys automatically. `CamelJson`
  (included into `Representation`) does the `lower_case_and_underscored` →
  `camelCase` conversion.
- **The gotcha:** serialization (Ruby → JSON) auto-camelizes, but
  **deserialization (`from_hash`) is manual** — you must read the exact
  camelCase string keys Keycloak returns. If a key is misspelled or left
  snake_case in `from_hash`, the attr silently stays nil. There is no symmetry
  helper for the read path.
- One known inconsistency: `ProtocolMapperRepresentation` keeps `protocolMapper`
  as a **literal attr name** (not `protocol_mapper`), so its `from_hash`/attr
  don't follow the snake_case rule. Don't "fix" it by reflex — match whatever a
  representation already does.
- **Namespacing:** the `Representation` base class is **top-level / global** (not
  under `KeycloakAdmin`), while every concrete representation IS under
  `module KeycloakAdmin`. When you reference the base in a spec it's
  `Representation`; concrete classes are `KeycloakAdmin::ClientScopeRepresentation`.

## Spec conventions

`spec/spec_helper.rb` requires the lib and defines:

- **`configure`** — sets a fake `server_url = "http://auth.service.io/auth"`,
  realm `master2`, service-account mode. Call it in `before` blocks.
- **`stub_token_client`** — stubs `TokenClient#get` so no real token call is
  made.
- **`stub_net_http_res(res_class, code, message)`** — builds a `Net::HTTP`
  response for `created_id`/status assertions.

**Unit specs** (`spec/client/`, `spec/representation/`, `spec/resource/`) are
pure — no network:

- Call the accessor (`KeycloakAdmin.realm(realm_name).<thing>`) and assert
  `ArgumentError` when the realm is nil.
- A `#<thing>_url` block asserts the exact collection vs item URL strings.
- For CRUD: `stub_token_client` + `allow_any_instance_of(RestClient::Resource).to
  receive(:get/:post/:put/:delete).and_return '<json or "">'`, then assert the
  parsed representation's fields.
- Representation spec: `described_class.from_hash({ ...camelCase string keys... })`
  and assert each attr plus that nested objects are the right representation
  class (`be_a(KeycloakAdmin::ProtocolMapperRepresentation)`).

**Integration specs** (`spec/integration/`) hit a real Keycloak. Every example
starts with `skip unless ENV["GITHUB_ACTIONS"]` and reconfigures to
`http://localhost:8080/`, `use_service_account=false`, admin/admin against realm
`dummy` / client `dummy-client`. They run only in CI.

Run everything with `bundle exec rspec`.

## Configuration & auth

`Configuration` (`lib/keycloak-admin/configuration.rb`) exposes
`server_url, server_domain, client_id, client_secret, client_realm_name,
use_service_account, username, password, logger, rest_client_options` (in practice every example in this repo sets only `server_url`; `server_domain` is an alternative base setting from the original gem — prefer `server_url`). Two grant
modes are selected by `use_service_account`:

- **`true` (default):** `grant_type=client_credentials`; the auth header is HTTP
  Basic `Base64(client_id:client_secret)`.
- **`false`:** `grant_type=password` body carrying username/password/client_id/
  client_secret; no extra Basic header.

`Configuration#body_for_token_retrieval` and `#headers_for_token_retrieval`
branch on `use_service_account`. Defaults set in
`KeycloakAdmin.load_configuration`: `client_id="admin-cli"`,
`client_realm_name=""`, `use_service_account=true`, `logger=Logger.new(STDOUT)`,
`rest_client_options={}`. `server_url`/`server_domain` default nil and are
required.

## Packaging

- The gemspec ships `spec.files = git ls-files`, so **new files must be
  `git add`-ed** or they won't be packaged — an untracked client/representation
  is invisible to consumers even though local specs pass.
- Runtime deps are only `http-cookie` and `rest-client` (`~> 2.0`). Keep the
  dependency surface minimal; don't add a runtime gem for convenience.
- The version lives in `lib/keycloak-admin/version.rb` (`VERSION = "..."`); bump
  it when releasing.
