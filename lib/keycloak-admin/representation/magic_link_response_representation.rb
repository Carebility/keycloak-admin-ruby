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
  end
end
