RSpec.describe KeycloakAdmin::AuthenticatorConfigRepresentation do
  describe "#from_hash" do
    before(:each) do
      json = <<-JSON
      {
        "id": "cfg-001",
        "alias": "idp-redirector-config",
        "config": {
          "defaultProvider": "my-saml-idp"
        }
      }
      JSON
      payload = JSON.parse(json)
      @config = KeycloakAdmin::AuthenticatorConfigRepresentation.from_hash(payload)
    end

    it "parses the id" do
      expect(@config.id).to eq "cfg-001"
    end

    it "parses the alias" do
      expect(@config.alias).to eq "idp-redirector-config"
    end

    it "parses the config hash" do
      expect(@config.config).to eq({ "defaultProvider" => "my-saml-idp" })
    end

    it "defaults config to empty hash when nil" do
      rep = KeycloakAdmin::AuthenticatorConfigRepresentation.from_hash({ "id" => "x" })
      expect(rep.config).to eq({})
    end

    it "returns nil for nil hash" do
      expect(KeycloakAdmin::AuthenticatorConfigRepresentation.from_hash(nil)).to be_nil
    end
  end

  describe "#to_json" do
    it "converts to camelCase JSON" do
      cfg        = KeycloakAdmin::AuthenticatorConfigRepresentation.new
      cfg.id     = "cfg-001"
      cfg.alias  = "idp-redirector-config"
      cfg.config = { "defaultProvider" => "my-saml-idp" }

      parsed = JSON.parse(cfg.to_json)
      expect(parsed["id"]).to eq "cfg-001"
      expect(parsed["alias"]).to eq "idp-redirector-config"
      expect(parsed["config"]).to eq({ "defaultProvider" => "my-saml-idp" })
    end

    it "leaves free-form config keys verbatim, including underscores" do
      cfg        = KeycloakAdmin::AuthenticatorConfigRepresentation.new
      cfg.config = { "max_retries" => "3", "client_secret" => "abc" }

      # Camelizing these keys would silently send the wrong settings to Keycloak.
      expect(JSON.parse(cfg.to_json)["config"]).to eq(
        "max_retries" => "3", "client_secret" => "abc"
      )
    end

    it "does not raise when a config key is an empty string" do
      cfg        = KeycloakAdmin::AuthenticatorConfigRepresentation.new
      cfg.config = { "" => "value" }

      expect { cfg.to_json }.not_to raise_error
      expect(JSON.parse(cfg.to_json)["config"]).to eq({ "" => "value" })
    end
  end
end
