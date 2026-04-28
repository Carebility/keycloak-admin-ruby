RSpec.describe KeycloakAdmin::ClientScopeClient do
  describe "#initialize" do
    let(:realm_name) { nil }

    before(:each) do
      @realm = KeycloakAdmin.realm(realm_name)
    end

    context "when realm_name is defined" do
      let(:realm_name) { "master" }

      it "does not raise any error" do
        expect { @realm.client_scopes }.to_not raise_error
      end
    end

    context "when realm_name is not defined" do
      it "raises argument error" do
        expect { @realm.client_scopes }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#client_scopes_url" do
    let(:realm_name) { "valid-realm" }
    let(:client_scope_id) { nil }
    let(:client_scope_client) { KeycloakAdmin.realm(realm_name).client_scopes }

    it "returns the collection url when client_scope_id is nil" do
      expect(client_scope_client.client_scopes_url(client_scope_id)).to eq "http://auth.service.io/auth/admin/realms/valid-realm/client-scopes"
    end

    context "when client_scope_id is defined" do
      let(:client_scope_id) { "scope-id-123" }

      it "returns item url with client scope id" do
        expect(client_scope_client.client_scopes_url(client_scope_id)).to eq "http://auth.service.io/auth/admin/realms/valid-realm/client-scopes/scope-id-123"
      end
    end
  end

  describe "#list" do
    let(:realm_name) { "valid-realm" }

    before(:each) do
      @client_scope_client = KeycloakAdmin.realm(realm_name).client_scopes
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return '[{"id":"scope-id-1","name":"profile","description":"Profile scope","protocol":"openid-connect","attributes":{"include.in.token.scope":"true"}}]'
    end

    it "returns a list of client scopes" do
      response = @client_scope_client.list
      expect(response.length).to eq 1
      expect(response.first.id).to eq "scope-id-1"
      expect(response.first.name).to eq "profile"
      expect(response.first.description).to eq "Profile scope"
      expect(response.first.protocol).to eq "openid-connect"
      expect(response.first.attributes["include.in.token.scope"]).to eq "true"
    end
  end

  describe "#get" do
    let(:realm_name) { "valid-realm" }
    let(:client_scope_id) { "scope-id-1" }

    before(:each) do
      @client_scope_client = KeycloakAdmin.realm(realm_name).client_scopes
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return '{"id":"scope-id-1","name":"profile","description":"Profile scope","protocol":"openid-connect"}'
    end

    it "returns client scope representation" do
      response = @client_scope_client.get(client_scope_id)
      expect(response.id).to eq "scope-id-1"
      expect(response.name).to eq "profile"
      expect(response.description).to eq "Profile scope"
      expect(response.protocol).to eq "openid-connect"
    end

    it "raises argument error when client_scope_id is nil" do
      expect { @client_scope_client.get(nil) }.to raise_error(ArgumentError)
    end
  end

  describe "#create!" do
    let(:realm_name) { "valid-realm" }

    before(:each) do
      @client_scope_client = KeycloakAdmin.realm(realm_name).client_scopes
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return ""
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return '[{"id":"scope-id-1","name":"profile","description":"Profile scope","protocol":"openid-connect"}]'
    end

    it "creates and returns the client scope" do
      response = @client_scope_client.create!(
        KeycloakAdmin::ClientScopeRepresentation.from_hash(
          "name" => "profile",
          "description" => "Profile scope",
          "protocol" => "openid-connect"
        )
      )
      expect(response).to be_a(KeycloakAdmin::ClientScopeRepresentation)
      expect(response.name).to eq "profile"
    end
  end

  describe "#update" do
    let(:realm_name) { "valid-realm" }
    let(:client_scope_id) { "scope-id-1" }

    before(:each) do
      @client_scope_client = KeycloakAdmin.realm(realm_name).client_scopes
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:put).and_return ""
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return '{"id":"scope-id-1","name":"profile","description":"Updated scope","protocol":"openid-connect"}'
    end

    it "updates and returns the client scope" do
      response = @client_scope_client.update(client_scope_id, {description: "Updated scope"})
      expect(response.description).to eq "Updated scope"
    end

    it "raises argument error when client_scope_id is nil" do
      expect { @client_scope_client.update(nil, {}) }.to raise_error(ArgumentError)
    end
  end

  describe "#delete" do
    let(:realm_name) { "valid-realm" }
    let(:client_scope_id) { "scope-id-1" }

    before(:each) do
      @client_scope_client = KeycloakAdmin.realm(realm_name).client_scopes
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:delete).and_return ""
    end

    it "deletes a client scope and returns true" do
      expect(@client_scope_client.delete(client_scope_id)).to eq true
    end

    it "raises argument error when client_scope_id is nil" do
      expect { @client_scope_client.delete(nil) }.to raise_error(ArgumentError)
    end
  end
end
