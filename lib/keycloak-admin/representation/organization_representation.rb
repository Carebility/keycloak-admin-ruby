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

    def self.from_hash(hash)
      organization              = new
      organization.id           = hash["id"]
      organization.name         = hash["name"]
      organization.alias        = hash["alias"]
      organization.enabled      = hash["enabled"]
      organization.description  = hash["description"]
      organization.redirect_url = hash["redirectUrl"]
      organization.attributes   = hash["attributes"]
      organization.domains      = hash["domains"]&.map { |hash| OrganizationDomainRepresentation.from_hash(hash) } || []
      organization.identity_providers = hash["identityProviders"]&.map { |hash| IdentityProviderRepresentation.from_hash(hash) } || []
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
