RSpec.describe KeycloakAdmin::IdentityProviderClient do
  describe "#identity_providers_url" do
    let(:realm_name)  { "valid-realm" }
    let(:provider_id) { nil }

    before(:each) do
      @built_url = KeycloakAdmin.realm(realm_name).identity_providers.identity_providers_url(provider_id)
    end

    context "when provider_id is not defined" do
      let(:provider_id) { nil }
      it "returns a proper url without provider id" do
        expect(@built_url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/identity-provider/instances"
      end
    end

    context "when provider_id is defined" do
      let(:provider_id) { "95985b21-d884-4bbd-b852-cb8cd365afc2" }
      it "returns a proper url with the provider id" do
        expect(@built_url).to eq "http://auth.service.io/auth/admin/realms/valid-realm/identity-provider/instances/95985b21-d884-4bbd-b852-cb8cd365afc2"
      end
    end
  end

  describe "#list" do
    let(:realm_name) { "valid-realm" }
    let(:json_response) do
      <<-JSON
      [
        {
          "alias": "acme",
          "displayName": "ACME",
          "internalId": "20fea77e-ae3d-411e-9467-2b3a20cd3e6d",
          "providerId": "saml",
          "enabled": true,
          "updateProfileFirstLoginMode": "on",
          "trustEmail": true,
          "storeToken": false,
          "addReadTokenRoleOnCreate": false,
          "authenticateByDefault": false,
          "linkOnly": false,
          "firstBrokerLoginFlowAlias": "first broker login",
          "config": {
            "hideOnLoginPage": "",
            "validateSignature": "true",
            "samlXmlKeyNameTranformer": "KEY_ID",
            "signingCertificate": "",
            "postBindingLogout": "false",
            "nameIDPolicyFormat": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
            "postBindingResponse": "true",
            "backchannelSupported": "",
            "signatureAlgorithm": "RSA_SHA256",
            "wantAssertionsEncrypted": "false",
            "xmlSigKeyInfoKeyNameTransformer": "CERT_SUBJECT",
            "useJwksUrl": "true",
            "wantAssertionsSigned": "true",
            "postBindingAuthnRequest": "true",
            "forceAuthn": "",
            "wantAuthnRequestsSigned": "true",
            "singleSignOnServiceUrl": "https://login.microsoftonline.com/test/saml2",
            "addExtensionsElementWithKeyInfo": "false"
          }
        }
      ]
      JSON
    end
    before(:each) do
      @identity_provider_client = KeycloakAdmin.realm(realm_name).identity_providers

      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return json_response
    end

    it "lists identity providers" do
      identity_providers = @identity_provider_client.list
      expect(identity_providers.length).to eq 1
      expect(identity_providers[0].alias).to eq "acme"
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/identity-provider/instances", rest_client_options).and_call_original

      identity_providers = @identity_provider_client.list
      expect(identity_providers.length).to eq 1
      expect(identity_providers[0].alias).to eq "acme"
    end
  end

  describe "#update" do
    let(:realm_name) { "valid-realm" }
    let(:idp_alias) { "acme" }
    let(:idp_rep) do
      KeycloakAdmin::IdentityProviderRepresentation.from_hash(
        "alias" => "acme", "displayName" => "ACME Updated", "providerId" => "saml",
        "enabled" => true, "config" => {}
      )
    end

    before(:each) do
      @identity_provider_client = KeycloakAdmin.realm(realm_name).identity_providers
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:put).and_return ''
    end

    it "updates an identity provider" do
      expect(@identity_provider_client.update(idp_alias, idp_rep)).to eq true
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/identity-provider/instances/acme", rest_client_options).and_call_original

      @identity_provider_client.update(idp_alias, idp_rep)
    end
  end

  describe "#delete" do
    let(:realm_name) { "valid-realm" }
    let(:idp_alias) { "acme" }

    before(:each) do
      @identity_provider_client = KeycloakAdmin.realm(realm_name).identity_providers
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:delete).and_return ''
    end

    it "deletes an identity provider" do
      expect(@identity_provider_client.delete(idp_alias)).to eq true
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/identity-provider/instances/acme", rest_client_options).and_call_original

      @identity_provider_client.delete(idp_alias)
    end
  end

  describe "#list_mappers" do
    let(:realm_name) { "valid-realm" }
    let(:idp_alias) { "acme" }
    let(:json_response) do
      <<-JSON
      [
        {
          "id": "mapper-001",
          "name": "email-mapper",
          "identityProviderAlias": "acme",
          "identityProviderMapper": "hardcoded-attribute-idp-mapper",
          "config": {
            "syncMode": "INHERIT",
            "attribute": "email"
          }
        }
      ]
      JSON
    end

    before(:each) do
      @identity_provider_client = KeycloakAdmin.realm(realm_name).identity_providers
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:get).and_return json_response
    end

    it "lists mappers for an identity provider" do
      mappers = @identity_provider_client.list_mappers(idp_alias)
      expect(mappers.length).to eq 1
      expect(mappers[0].id).to eq "mapper-001"
      expect(mappers[0].name).to eq "email-mapper"
      expect(mappers[0].identity_provider_alias).to eq "acme"
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/identity-provider/instances/acme/mappers", rest_client_options).and_call_original

      @identity_provider_client.list_mappers(idp_alias)
    end
  end

  describe "#update_mapping" do
    let(:realm_name) { "valid-realm" }
    let(:idp_alias) { "acme" }
    let(:mapper_id) { "mapper-001" }
    let(:mapper_rep) do
      KeycloakAdmin::IdentityProviderMapperRepresentation.from_hash(
        "id" => "mapper-001", "name" => "email-mapper",
        "identityProviderAlias" => "acme",
        "identityProviderMapper" => "hardcoded-attribute-idp-mapper",
        "config" => { "attribute" => "email" }
      )
    end

    before(:each) do
      @identity_provider_client = KeycloakAdmin.realm(realm_name).identity_providers
      stub_token_client
      allow_any_instance_of(RestClient::Resource).to receive(:put).and_return ''
    end

    it "updates a mapper" do
      expect(@identity_provider_client.update_mapping(idp_alias, mapper_id, mapper_rep)).to eq true
    end

    it "passes rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/admin/realms/valid-realm/identity-provider/instances/acme/mappers/mapper-001", rest_client_options).and_call_original

      @identity_provider_client.update_mapping(idp_alias, mapper_id, mapper_rep)
    end
  end
end
