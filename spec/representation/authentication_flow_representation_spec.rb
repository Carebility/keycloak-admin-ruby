RSpec.describe KeycloakAdmin::AuthenticationFlowRepresentation do
  describe "#from_hash" do
    before(:each) do
      json = <<-JSON
      {
        "id": "be791dad-ad52-4dbe-b93b-bef5cfd3a498",
        "alias": "browser",
        "description": "browser based authentication",
        "providerId": "basic-flow",
        "topLevel": true,
        "builtIn": true,
        "authenticationExecutions": []
      }
      JSON
      payload = JSON.parse(json)
      @flow   = KeycloakAdmin::AuthenticationFlowRepresentation.from_hash(payload)
    end

    it "parses the id" do
      expect(@flow.id).to eq "be791dad-ad52-4dbe-b93b-bef5cfd3a498"
    end

    it "parses the alias" do
      expect(@flow.alias).to eq "browser"
    end

    it "parses the description" do
      expect(@flow.description).to eq "browser based authentication"
    end

    it "parses the provider_id" do
      expect(@flow.provider_id).to eq "basic-flow"
    end

    it "parses top_level" do
      expect(@flow.top_level).to eq true
    end

    it "parses built_in" do
      expect(@flow.built_in).to eq true
    end

    it "parses authentication_executions" do
      expect(@flow.authentication_executions).to eq []
    end

    it "returns nil for nil hash" do
      expect(KeycloakAdmin::AuthenticationFlowRepresentation.from_hash(nil)).to be_nil
    end
  end

  describe "#to_json" do
    it "converts to camelCase JSON" do
      flow             = KeycloakAdmin::AuthenticationFlowRepresentation.new
      flow.id          = "test-id"
      flow.alias       = "my-flow"
      flow.description = "A test flow"
      flow.provider_id = "basic-flow"
      flow.top_level   = true
      flow.built_in    = false

      parsed = JSON.parse(flow.to_json)
      expect(parsed["id"]).to eq "test-id"
      expect(parsed["alias"]).to eq "my-flow"
      expect(parsed["description"]).to eq "A test flow"
      expect(parsed["providerId"]).to eq "basic-flow"
      expect(parsed["topLevel"]).to eq true
      expect(parsed["builtIn"]).to eq false
    end
  end
end
