module KeycloakAdmin
  class OrganizationClient < Client
    def initialize(configuration, realm_client)
      super(configuration)
      raise ArgumentError.new("realm must be defined") unless realm_client.name_defined?
      @realm_client = realm_client
    end

    def create!(organization_representation)
      if organization_representation.class != OrganizationRepresentation
        organization_representation = OrganizationRepresentation.from_hash(organization_representation)
      end
      save(organization_representation)
      search(organization_representation.name)&.last
    end

    def save(organization_representation)
      execute_http do
        RestClient::Resource.new(organizations_url, @configuration.rest_client_options).post(
          create_payload(organization_representation), headers
        )
      end
    end

    # pay attention that, since Keycloak 24.0.4, partial updates of attributes are not authorized anymore
    def update(organization_id, organization_representation_body)
      raise ArgumentError.new("organization_id must be defined") if organization_id.nil?
      RestClient::Request.execute(
        @configuration.rest_client_options.merge(
          method: :put,
          url: organizations_url(organization_id),
          payload: create_payload(organization_representation_body),
          headers: headers
        )
      )
    end

    def get(organization_id)
      response = execute_http do
        RestClient::Resource.new(organizations_url(organization_id), @configuration.rest_client_options).get(headers)
      end
      OrganizationRepresentation.from_hash(JSON.parse(response))
    end

    def search(query)
      derived_headers = case query
                        when String
                          headers.merge({params: { search: query }})
                        when Hash
                          headers.merge({params: query })
                        else
                          headers
                        end

      response = execute_http do
        RestClient::Resource.new(organizations_url, @configuration.rest_client_options).get(derived_headers)
      end
      JSON.parse(response).map { |organization_as_hash| OrganizationRepresentation.from_hash(organization_as_hash) }
    end

    def list
      search(nil)
    end

    def delete(organization_id)
      execute_http do
        RestClient::Resource.new(organizations_url(organization_id), @configuration.rest_client_options).delete(headers)
      end
      true
    end

    def add_member(organization_id, user_id)
      execute_http do
        RestClient::Resource.new(organization_members_url(organization_id), @configuration.rest_client_options).post(user_id, headers)
      end
      true
    end

    def remove_member(organization_id, user_id)
      execute_http do
        RestClient::Resource.new(organization_members_url(organization_id, user_id), @configuration.rest_client_options).delete(headers)
      end
      true
    end

    def members(organization_id)
      response = execute_http do
        RestClient::Resource.new(organization_members_url(organization_id), @configuration.rest_client_options).get(headers)
      end
      JSON.parse(response).map { |user_as_hash| UserRepresentation.from_hash(user_as_hash) }
    end

    def get_member(organization_id, user_id)
      response = execute_http do
        RestClient::Resource.new(organization_members_url(organization_id, user_id), @configuration.rest_client_options).get(headers)
      end
      UserRepresentation.from_hash(JSON.parse(response))
    end

    def get_member_organizations(user_id)
      response = execute_http do
        RestClient::Resource.new(member_organizations_url(user_id), @configuration.rest_client_options).get(headers)
      end
      JSON.parse(response).map { |organization_as_hash| OrganizationRepresentation.from_hash(organization_as_hash) }
    end

    def organizations_url(organization_id=nil)
      if organization_id
        "#{@realm_client.realm_admin_url}/organizations/#{organization_id}"
      else
        "#{@realm_client.realm_admin_url}/organizations"
      end
    end

    def organization_members_url(organization_id, user_id=nil)
      if user_id
        "#{organizations_url(organization_id)}/members/#{user_id}"
      else
        "#{organizations_url(organization_id)}/members"
      end
    end

    def member_organizations_url(user_id)
      "#{organizations_url}/members/#{user_id}/organizations"
    end
  end
end
