module KeycloakAdmin
  class ClientScopeClient < Client
    def initialize(configuration, realm_client)
      super(configuration)
      raise ArgumentError.new("realm must be defined") unless realm_client.name_defined?
      @realm_client = realm_client
    end

    def create!(client_scope_representation)
      if client_scope_representation.class != ClientScopeRepresentation
        client_scope_representation = ClientScopeRepresentation.from_hash(client_scope_representation)
      end

      save(client_scope_representation)
      list.find { |client_scope| client_scope.name == client_scope_representation.name }
    end

    def save(client_scope_representation)
      execute_http do
        RestClient::Resource.new(client_scopes_url, @configuration.rest_client_options).post(
          create_payload(client_scope_representation), headers
        )
      end
    end

    def list
      response = execute_http do
        RestClient::Resource.new(client_scopes_url, @configuration.rest_client_options).get(headers)
      end

      JSON.parse(response).map { |client_scope_as_hash| ClientScopeRepresentation.from_hash(client_scope_as_hash) }
    end

    def get(client_scope_id)
      raise ArgumentError.new("client_scope_id must be defined") if client_scope_id.nil?

      response = execute_http do
        RestClient::Resource.new(client_scopes_url(client_scope_id), @configuration.rest_client_options).get(headers)
      end

      ClientScopeRepresentation.from_hash(JSON.parse(response))
    end

    def find_by_name(name)
      list.find { |client_scope| client_scope.name == name }
    end

    def update(client_scope_id, client_scope_representation_body)
      raise ArgumentError.new("client_scope_id must be defined") if client_scope_id.nil?

      execute_http do
        RestClient::Resource.new(client_scopes_url(client_scope_id), @configuration.rest_client_options).put(
          create_payload(client_scope_representation_body), headers
        )
      end

      get(client_scope_id)
    end

    def delete(client_scope_id)
      raise ArgumentError.new("client_scope_id must be defined") if client_scope_id.nil?

      execute_http do
        RestClient::Resource.new(client_scopes_url(client_scope_id), @configuration.rest_client_options).delete(headers)
      end

      true
    end

    def client_scopes_url(client_scope_id=nil)
      if client_scope_id
        "#{@realm_client.realm_admin_url}/client-scopes/#{client_scope_id}"
      else
        "#{@realm_client.realm_admin_url}/client-scopes"
      end
    end
  end
end
