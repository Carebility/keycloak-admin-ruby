module KeycloakAdmin
  class ClientScopeRepresentation < Representation
    attr_accessor :id,
                  :name,
                  :description,
                  :protocol,
                  :attributes,
                  :protocol_mappers

    def self.from_hash(hash)
      client_scope                  = new
      client_scope.id               = hash["id"]
      client_scope.name             = hash["name"]
      client_scope.description      = hash["description"]
      client_scope.protocol         = hash["protocol"]
      client_scope.attributes       = hash["attributes"] || {}
      client_scope.protocol_mappers = (hash["protocolMappers"] || []).map { |mapper_hash| ProtocolMapperRepresentation.from_hash(mapper_hash) }
      client_scope
    end
  end
end
