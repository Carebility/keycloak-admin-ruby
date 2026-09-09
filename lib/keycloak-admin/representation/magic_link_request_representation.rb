module KeycloakAdmin
  # Request body for `POST /realms/{realm}/magic-link` (phasetwo keycloak-magic-link).
  #
  # Unlike the Keycloak Admin API, the plugin reads snake_case JSON field names
  # (`client_id`, `redirect_uri`, `expiration_seconds`, ...), so this
  # representation opts out of the camelization every other representation gets
  # from `Representation#as_json`. Nil attributes are omitted from the payload,
  # except the boolean flags, which are always serialized (see `as_json`).
  #
  # The boolean flags default to `false` in the gem even where the plugin's own
  # default is `true` (`reusable`), so a caller who forgets a field gets a
  # single-use link that neither creates users nor sends email.
  class MagicLinkRequestRepresentation < Representation
    attr_accessor :email,
      :username,
      :client_id,
      :redirect_uri,
      :expiration_seconds,
      :force_create,
      :update_password,
      :update_profile,
      :send_email,
      :reusable,
      :remember_me,
      :scope,
      :nonce,
      :state,
      :code_challenge,
      :code_challenge_method,
      :response_mode

    # Flags that must always be present in the payload. If one were omitted the
    # plugin would apply its own default, and for `reusable` that default is
    # `true` — an explicit nil must not fail open.
    BOOLEAN_FLAGS = %w[force_create update_password update_profile send_email reusable remember_me].freeze

    def initialize
      @force_create    = false
      @update_password = false
      @update_profile  = false
      @send_email      = false
      @reusable        = false
      @remember_me     = false
    end

    # Reads the plugin's snake_case keys. Absent boolean flags keep the gem's
    # safe defaults instead of being reset to nil (which would drop them from
    # the payload and hand control back to the plugin's defaults).
    def self.from_hash(hash)
      request                       = new
      request.email                 = hash["email"]
      request.username              = hash["username"]
      request.client_id             = hash["client_id"]
      request.redirect_uri          = hash["redirect_uri"]
      request.expiration_seconds    = hash["expiration_seconds"]
      request.force_create          = hash.fetch("force_create", request.force_create)
      request.update_password       = hash.fetch("update_password", request.update_password)
      request.update_profile        = hash.fetch("update_profile", request.update_profile)
      request.send_email            = hash.fetch("send_email", request.send_email)
      request.reusable              = hash.fetch("reusable", request.reusable)
      request.remember_me           = hash.fetch("remember_me", request.remember_me)
      request.scope                 = hash["scope"]
      request.nonce                 = hash["nonce"]
      request.state                 = hash["state"]
      request.code_challenge        = hash["code_challenge"]
      request.code_challenge_method = hash["code_challenge_method"]
      request.response_mode         = hash["response_mode"]
      request
    end

    # Snake_case keys, exactly as the attribute names. The boolean flags are
    # always present and coerced with `!!` (so an explicit nil serializes as
    # `false` rather than being dropped); every other nil value is omitted.
    def as_json(options=nil)
      json = instance_variables.each_with_object({}) do |ivar, acc|
        name  = ivar.to_s[1..-1]
        value = instance_variable_get(ivar)
        if BOOLEAN_FLAGS.include?(name)
          acc[name] = !!value
        elsif !value.nil?
          acc[name] = value
        end
      end
      BOOLEAN_FLAGS.each { |flag| json[flag] = false unless json.key?(flag) }
      json
    end
  end
end
