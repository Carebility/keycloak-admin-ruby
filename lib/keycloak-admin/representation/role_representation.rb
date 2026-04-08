module KeycloakAdmin
  class RoleRepresentation < Representation
    attr_accessor :id,
      :name,
      :description,
      :scope_param_required,
      :composite,
      :composites,
      :client_role,
      :container_id,
      :attributes,
    def self.from_hash(hash)
      role             = new
      role.id          = hash["id"]
      role.name        = hash["name"]
      role.description = hash["description"]
      role.scope_param_required = hash["scopeParamRequired"]
      role.composite   = hash["composite"]
      role.composites = hash["composites"]
      role.client_role = hash["clientRole"]
      role.container_id = hash["containerId"]
      role.attributes = hash["attributes"]
      role
    end
  end
end
