module KeycloakAdmin
  # Client for the phasetwo `keycloak-magic-link` REST extension.
  #
  # The endpoint is realm-rooted (`/realms/{realm}/magic-link`), NOT under
  # `/admin/realms`, and it authorizes with the same bearer token the admin API
  # uses (the caller needs `manage-users`).
  class MagicLinkClient < Client
    def initialize(configuration, realm_client)
      super(configuration)
      raise ArgumentError.new("realm must be defined") unless realm_client.name_defined?
      @realm_client = realm_client
    end

    def create(magic_link_request_representation)
      raise ArgumentError.new("magic_link_request_representation must be defined") if magic_link_request_representation.nil?
      unless magic_link_request_representation.is_a?(MagicLinkRequestRepresentation)
        raise ArgumentError.new("magic_link_request_representation must be a MagicLinkRequestRepresentation")
      end
      raise ArgumentError.new("expiration_seconds must be defined") if magic_link_request_representation.expiration_seconds.nil?
      if magic_link_request_representation.email.nil? && magic_link_request_representation.username.nil?
        raise ArgumentError.new("email or username must be defined")
      end

      response = execute_http do
        RestClient::Resource.new(magic_link_url, @configuration.rest_client_options).post(
          create_payload(magic_link_request_representation), headers
        )
      end
      MagicLinkResponseRepresentation.from_hash(JSON.parse(response))
    end

    def magic_link_url
      "#{@realm_client.realm_url}/magic-link"
    end
  end
end
