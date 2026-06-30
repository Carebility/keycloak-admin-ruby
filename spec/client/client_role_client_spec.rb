RSpec.describe KeycloakAdmin::ClientRoleClient do
  describe "#clients_url" do
    let(:realm_name) { "valid-realm" }
    let(:client_id) { "95985b21-d884-4bbd-b852-cb8cd365afc2" }

    it "returns a proper url for a client's roles" do
      built_url = KeycloakAdmin.realm(realm_name).client_roles.clients_url(client_id)
      expect(built_url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/clients/95985b21-d884-4bbd-b852-cb8cd365afc2/roles"
    end
  end

  describe "#list" do
    let(:realm_name) { "valid-realm" }
    let(:client_id) { "95985b21-d884-4bbd-b852-cb8cd365afc2" }

    before(:each) do
      @client_role_client = KeycloakAdmin.realm(realm_name).client_roles

      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return '[{"id":"test_role_id","name":"test_role_name"}]'
    end

    it "lists client roles" do
      roles = @client_role_client.list(client_id)
      expect(roles.length).to eq 1
      expect(roles[0].name).to eq "test_role_name"
    end
  end

  describe "#create" do
    let(:realm_name) { "valid-realm" }
    let(:client_id) { "95985b21-d884-4bbd-b852-cb8cd365afc2" }
    let(:role) { KeycloakAdmin::RoleRepresentation.from_hash(
      "name" => "test_role_name",
      "description" => "a test role",
      "composite" => false,
      "clientRole" => true
    )}

    before(:each) do
      @client_role_client = KeycloakAdmin.realm(realm_name).client_roles

      stub_token_client
      expect_any_instance_of(RestClient::Resource).to receive(:post).with(role.to_json, anything)
    end

    it "creates a client role" do
      @client_role_client.create(client_id, role)
    end

    it "posts to the client's roles endpoint" do
      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/clients/#{client_id}/roles", anything).and_call_original

      @client_role_client.create(client_id, role)
    end
  end
end
