module KeycloakAdmin
  class AuthenticationFlowRepresentation < Representation
    attr_accessor :id,
                  :alias,
                  :description,
                  :provider_id,
                  :top_level,
                  :built_in,
                  :authentication_executions

    def self.from_hash(hash)
      if hash.nil?
        nil
      else
        rep                             = new
        rep.id                          = hash["id"]
        rep.alias                       = hash["alias"]
        rep.description                 = hash["description"]
        rep.provider_id                 = hash["providerId"]
        rep.top_level                   = hash["topLevel"]
        rep.built_in                    = hash["builtIn"]
        rep.authentication_executions   = hash["authenticationExecutions"]
        rep
      end
    end
  end
end
