module KeycloakAdmin
  class AuthenticationExecutionInfoRepresentation < Representation
    attr_accessor :id,
                  :requirement,
                  :display_name,
                  :alias,
                  :description,
                  :requirement_choices,
                  :configurable,
                  :authentication_flow,
                  :provider_id,
                  :authentication_config,
                  :flow_id,
                  :level,
                  :index,
                  :priority

    def self.from_hash(hash)
      if hash.nil?
        nil
      else
        rep                         = new
        rep.id                      = hash["id"]
        rep.requirement             = hash["requirement"]
        rep.display_name            = hash["displayName"]
        rep.alias                   = hash["alias"]
        rep.description             = hash["description"]
        rep.requirement_choices     = hash["requirementChoices"]
        rep.configurable            = hash["configurable"]
        rep.authentication_flow     = hash["authenticationFlow"]
        rep.provider_id             = hash["providerId"]
        rep.authentication_config   = hash["authenticationConfig"]
        rep.flow_id                 = hash["flowId"]
        rep.level                   = hash["level"]
        rep.index                   = hash["index"]
        rep.priority                = hash["priority"]
        rep
      end
    end
  end
end
