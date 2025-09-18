module KeycloakAdmin
  class OrganizationRepresentation < Representation
    attr_accessor :id,
      :name,
      :alias,
      :enabled,
      :description,
      :redirect_url,
      :attributes,
      :domains,
      :members,
      :identity_providers

    def self.from_hash(organization_hash)
      organization              = new
      organization.id           = organization_hash["id"]
      organization.name         = organization_hash["name"]
      organization.alias        = organization_hash["alias"]
      organization.enabled      = organization_hash["enabled"]
      organization.description  = organization_hash["description"]
      organization.redirect_url = organization_hash["redirectUrl"]
      organization.attributes   = organization_hash["attributes"]
      organization.domains      = organization_hash["domains"]&.map { |hash| OrganizationDomainRepresentation.from_hash(hash) } || []
      organization.identity_providers = organization_hash["identityProviders"]&.map { |hash| IdentityProviderRepresentation.from_hash(hash) } || []
      organization
    end

    def add_domain(domain_representation)
      @domains ||= []
      @domains.push(domain_representation)
    end

    def add_identity_provider(identity_provider_representation)
      @identity_providers ||= []
      @identity_providers.push(identity_provider_representation)
    end
  end
end
