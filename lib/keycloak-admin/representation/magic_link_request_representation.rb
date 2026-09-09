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

    # Reads the plugin's snake_case keys. A boolean flag that is absent from the
    # hash keeps the gem's safe default (`false`); a flag that is present is
    # taken as given, including an explicit `nil`, which `as_json` serializes
    # as `false`. Either way every flag is always on the wire.
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
    # always present: `nil` serializes as `false` (never omitted, so the
    # plugin's own defaults never apply) and anything other than `true`,
    # `false` or `nil` raises — Ruby truthiness would turn `"false"` or `0`
    # into `true`, i.e. a reusable link from a caller who tried to say no.
    # Every other nil value is omitted.
    def as_json(options=nil)
      json = instance_variables.each_with_object({}) do |ivar, acc|
        name  = ivar.to_s[1..-1]
        value = instance_variable_get(ivar)
        if BOOLEAN_FLAGS.include?(name)
          acc[name] = boolean_flag(name, value)
        elsif !value.nil?
          acc[name] = value
        end
      end
      BOOLEAN_FLAGS.each { |flag| json[flag] = false unless json.key?(flag) }
      json
    end

    private

    def boolean_flag(name, value)
      return false if value.nil?
      return value if value == true || value == false

      raise ArgumentError.new("#{name} must be true, false or nil, got #{value.inspect}")
    end
  end
end
