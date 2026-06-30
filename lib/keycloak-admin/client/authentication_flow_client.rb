module KeycloakAdmin
  class AuthenticationFlowClient < Client
    def initialize(configuration, realm_client)
      super(configuration)
      raise ArgumentError.new("realm must be defined") unless realm_client.name_defined?
      @realm_client = realm_client
    end

    def list_flows
      response = execute_http do
        RestClient::Resource.new(flows_url, @configuration.rest_client_options).get(headers)
      end
      JSON.parse(response).map { |flow_as_hash| AuthenticationFlowRepresentation.from_hash(flow_as_hash) }
    end

    def find_flow_by_alias(flow_alias)
      list_flows.find { |flow| flow.alias == flow_alias }
    end

    def copy_flow(source_flow_alias, new_name)
      execute_http do
        RestClient::Resource.new(flow_copy_url(source_flow_alias), @configuration.rest_client_options).post(
          { "newName" => new_name }.to_json, headers
        )
      end
      true
    end

    def list_executions(flow_alias)
      response = execute_http do
        RestClient::Resource.new(flow_executions_url(flow_alias), @configuration.rest_client_options).get(headers)
      end
      JSON.parse(response).map { |exec_as_hash| AuthenticationExecutionInfoRepresentation.from_hash(exec_as_hash) }
    end

    def update_execution(flow_alias, execution_info_representation)
      execute_http do
        RestClient::Resource.new(flow_executions_url(flow_alias), @configuration.rest_client_options).put(
          create_payload(execution_info_representation), headers
        )
      end
      true
    end

    def add_execution(flow_alias, provider_id)
      response = execute_http do
        RestClient::Resource.new(flow_execution_create_url(flow_alias), @configuration.rest_client_options).post(
          { "provider" => provider_id }.to_json, headers
        )
      end
      created_id(response)
    end

    def create_execution_config(execution_id, authenticator_config_representation)
      response = execute_http do
        RestClient::Resource.new(execution_config_url(execution_id), @configuration.rest_client_options).post(
          create_payload(authenticator_config_representation), headers
        )
      end
      created_id(response)
    end

    def delete_execution(execution_id)
      execute_http do
        RestClient::Resource.new(execution_url(execution_id), @configuration.rest_client_options).delete(headers)
      end
      true
    end

    def flows_url(flow_alias=nil)
      if flow_alias
        "#{@realm_client.realm_admin_url}/authentication/flows/#{flow_alias}"
      else
        "#{@realm_client.realm_admin_url}/authentication/flows"
      end
    end

    def flow_executions_url(flow_alias)
      "#{flows_url(flow_alias)}/executions"
    end

    def flow_copy_url(source_flow_alias)
      "#{flows_url(source_flow_alias)}/copy"
    end

    def flow_execution_create_url(flow_alias)
      "#{flows_url(flow_alias)}/executions/execution"
    end

    def execution_config_url(execution_id)
      "#{@realm_client.realm_admin_url}/authentication/executions/#{execution_id}/config"
    end

    def execution_url(execution_id)
      "#{@realm_client.realm_admin_url}/authentication/executions/#{execution_id}"
    end
  end
end
