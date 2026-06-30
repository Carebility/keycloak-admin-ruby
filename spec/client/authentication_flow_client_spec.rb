RSpec.describe KeycloakAdmin::AuthenticationFlowClient do
  describe "#flows_url" do
    let(:realm_name) { "valid-realm" }

    it "returns a proper url without flow alias" do
      url = KeycloakAdmin.realm(realm_name).authentication.flows_url
      expect(url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows"
    end

    it "returns a proper url with flow alias" do
      url = KeycloakAdmin.realm(realm_name).authentication.flows_url("browser")
      expect(url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows/browser"
    end
  end

  describe "#flow_executions_url" do
    let(:realm_name) { "valid-realm" }

    it "returns a proper url" do
      url = KeycloakAdmin.realm(realm_name).authentication.flow_executions_url("browser")
      expect(url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows/browser/executions"
    end
  end

  describe "#flow_copy_url" do
    let(:realm_name) { "valid-realm" }

    it "returns a proper url" do
      url = KeycloakAdmin.realm(realm_name).authentication.flow_copy_url("browser")
      expect(url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows/browser/copy"
    end
  end

  describe "#flow_execution_create_url" do
    let(:realm_name) { "valid-realm" }

    it "returns a proper url" do
      url = KeycloakAdmin.realm(realm_name).authentication.flow_execution_create_url("browser")
      expect(url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows/browser/executions/execution"
    end
  end

  describe "#execution_config_url" do
    let(:realm_name) { "valid-realm" }

    it "returns a proper url" do
      url = KeycloakAdmin.realm(realm_name).authentication.execution_config_url("exec-001")
      expect(url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/authentication/executions/exec-001/config"
    end
  end

  describe "#execution_url" do
    let(:realm_name) { "valid-realm" }

    it "returns a proper url" do
      url = KeycloakAdmin.realm(realm_name).authentication.execution_url("exec-001")
      expect(url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/authentication/executions/exec-001"
    end
  end

  describe "#list_flows" do
    let(:realm_name) { "valid-realm" }
    let(:json_response) do
      <<-JSON
      [
        {
          "id": "flow-001",
          "alias": "browser",
          "description": "browser based authentication",
          "providerId": "basic-flow",
          "topLevel": true,
          "builtIn": true,
          "authenticationExecutions": []
        },
        {
          "id": "flow-002",
          "alias": "direct grant",
          "description": "direct grant based authentication",
          "providerId": "basic-flow",
          "topLevel": true,
          "builtIn": true,
          "authenticationExecutions": []
        }
      ]
      JSON
    end

    before(:each) do
      @auth_client = KeycloakAdmin.realm(realm_name).authentication
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return json_response
    end

    it "lists authentication flows" do
      flows = @auth_client.list_flows
      expect(flows.length).to eq 2
      expect(flows[0].alias).to eq "browser"
      expect(flows[0].id).to eq "flow-001"
      expect(flows[1].alias).to eq "direct grant"
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows", rest_client_options).and_call_original

      @auth_client.list_flows
    end
  end

  describe "#find_flow_by_alias" do
    let(:realm_name) { "valid-realm" }
    let(:json_response) do
      <<-JSON
      [
        {
          "id": "flow-001",
          "alias": "browser",
          "description": "browser based authentication",
          "providerId": "basic-flow",
          "topLevel": true,
          "builtIn": true,
          "authenticationExecutions": []
        }
      ]
      JSON
    end

    before(:each) do
      @auth_client = KeycloakAdmin.realm(realm_name).authentication
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return json_response
    end

    it "finds a flow by alias" do
      flow = @auth_client.find_flow_by_alias("browser")
      expect(flow).not_to be_nil
      expect(flow.id).to eq "flow-001"
    end

    it "returns nil when flow is not found" do
      flow = @auth_client.find_flow_by_alias("nonexistent")
      expect(flow).to be_nil
    end
  end

  describe "#copy_flow" do
    let(:realm_name) { "valid-realm" }

    before(:each) do
      @auth_client = KeycloakAdmin.realm(realm_name).authentication
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return ''
    end

    it "copies a flow" do
      expect(@auth_client.copy_flow("browser", "my-browser-copy")).to eq true
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows/browser/copy", rest_client_options).and_call_original

      @auth_client.copy_flow("browser", "my-browser-copy")
    end
  end

  describe "#list_executions" do
    let(:realm_name) { "valid-realm" }
    let(:json_response) do
      <<-JSON
      [
        {
          "id": "exec-001",
          "requirement": "ALTERNATIVE",
          "displayName": "Cookie",
          "configurable": false,
          "authenticationFlow": false,
          "providerId": "auth-cookie",
          "level": 0,
          "index": 0
        },
        {
          "id": "exec-002",
          "requirement": "ALTERNATIVE",
          "displayName": "Identity Provider Redirector",
          "configurable": true,
          "authenticationFlow": false,
          "providerId": "identity-provider-redirector",
          "level": 0,
          "index": 1
        }
      ]
      JSON
    end

    before(:each) do
      @auth_client = KeycloakAdmin.realm(realm_name).authentication
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return json_response
    end

    it "lists executions for a flow" do
      executions = @auth_client.list_executions("browser")
      expect(executions.length).to eq 2
      expect(executions[0].id).to eq "exec-001"
      expect(executions[0].provider_id).to eq "auth-cookie"
      expect(executions[1].provider_id).to eq "identity-provider-redirector"
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows/browser/executions", rest_client_options).and_call_original

      @auth_client.list_executions("browser")
    end
  end

  describe "#update_execution" do
    let(:realm_name) { "valid-realm" }
    let(:execution_rep) do
      KeycloakAdmin::AuthenticationExecutionInfoRepresentation.from_hash(
        "id" => "exec-001", "requirement" => "REQUIRED", "providerId" => "auth-cookie"
      )
    end

    before(:each) do
      @auth_client = KeycloakAdmin.realm(realm_name).authentication
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:put).and_return ''
    end

    it "updates an execution" do
      expect(@auth_client.update_execution("browser", execution_rep)).to eq true
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows/browser/executions", rest_client_options).and_call_original

      @auth_client.update_execution("browser", execution_rep)
    end
  end

  describe "#add_execution" do
    let(:realm_name) { "valid-realm" }

    before(:each) do
      @auth_client = KeycloakAdmin.realm(realm_name).authentication
      stub_token_client

      @response = double
      allow(@response).to receive(:headers).and_return(
        location: "http://auth.service.io/auth/admin/realms/valid-realm/authentication/executions/new-exec-id"
      )
      stub_net_http_res(Net::HTTPCreated, "201", "Created")
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return @response
    end

    it "adds an execution and returns the new id" do
      id = @auth_client.add_execution("browser", "identity-provider-redirector")
      expect(id).to eq "new-exec-id"
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/authentication/flows/browser/executions/execution", rest_client_options).and_call_original

      @auth_client.add_execution("browser", "identity-provider-redirector")
    end
  end

  describe "#create_execution_config" do
    let(:realm_name) { "valid-realm" }
    let(:config_rep) do
      KeycloakAdmin::AuthenticatorConfigRepresentation.from_hash(
        "alias" => "idp-redirector-config",
        "config" => { "defaultProvider" => "my-saml-idp" }
      )
    end

    before(:each) do
      @auth_client = KeycloakAdmin.realm(realm_name).authentication
      stub_token_client

      @response = double
      allow(@response).to receive(:headers).and_return(
        location: "http://auth.service.io/auth/admin/realms/valid-realm/authentication/config/new-config-id"
      )
      stub_net_http_res(Net::HTTPCreated, "201", "Created")
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return @response
    end

    it "creates execution config and returns the new config id" do
      id = @auth_client.create_execution_config("exec-001", config_rep)
      expect(id).to eq "new-config-id"
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/authentication/executions/exec-001/config", rest_client_options).and_call_original

      @auth_client.create_execution_config("exec-001", config_rep)
    end
  end

  describe "#delete_execution" do
    let(:realm_name) { "valid-realm" }

    before(:each) do
      @auth_client = KeycloakAdmin.realm(realm_name).authentication
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:delete).and_return ''
    end

    it "deletes an execution" do
      expect(@auth_client.delete_execution("exec-001")).to eq true
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/authentication/executions/exec-001", rest_client_options).and_call_original

      @auth_client.delete_execution("exec-001")
    end
  end
end
