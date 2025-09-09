module KeycloakAdmin
  class OrganizationDomainRepresentation < Representation
    attr_accessor :name,
      :verified

    def self.from_hash(hash)
      domain                  = new
      domain.name             = hash["name"]
      domain.verified         = hash["verified"]
      domain
    end
  end
end
