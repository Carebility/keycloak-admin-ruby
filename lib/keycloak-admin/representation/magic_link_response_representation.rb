module KeycloakAdmin
  # Response body of `POST /realms/{realm}/magic-link` (phasetwo keycloak-magic-link).
  # The plugin answers with snake_case keys: `user_id`, `link`, `sent`.
  class MagicLinkResponseRepresentation < Representation
    attr_accessor :user_id,
      :link,
      :sent

    def self.from_hash(hash)
      response         = new
      response.user_id = hash["user_id"]
      response.link    = hash["link"]
      response.sent    = hash["sent"]
      response
    end

    # The plugin's keys are snake_case, so unlike every other representation
    # this one must not camelize on the way out (`user_id`, never `userId`);
    # nil attributes are omitted so `from_json(to_json)` round-trips.
    def as_json(options=nil)
      instance_variables.each_with_object({}) do |ivar, acc|
        value = instance_variable_get(ivar)
        acc[ivar.to_s[1..-1]] = value unless value.nil?
      end
    end
  end
end
