module KeycloakAdmin
  class AuthenticatorConfigRepresentation < Representation
    attr_accessor :id,
                  :alias,
                  :config

    def self.from_hash(hash)
      if hash.nil?
        nil
      else
        rep        = new
        rep.id     = hash["id"]
        rep.alias  = hash["alias"]
        rep.config = hash["config"] || {}
        rep
      end
    end
  end
end
