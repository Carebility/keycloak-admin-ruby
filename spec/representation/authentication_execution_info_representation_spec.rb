RSpec.describe KeycloakAdmin::AuthenticationExecutionInfoRepresentation do
  describe "#from_hash" do
    before(:each) do
      json = <<-JSON
      {
        "id": "exec-001",
        "requirement": "ALTERNATIVE",
        "displayName": "Cookie",
        "alias": "cookie-alt",
        "description": "Cookie based authentication",
        "requirementChoices": ["REQUIRED", "ALTERNATIVE", "DISABLED"],
        "configurable": false,
        "authenticationFlow": false,
        "providerId": "auth-cookie",
        "authenticationConfig": "config-123",
        "flowId": "flow-456",
        "level": 0,
        "index": 1,
        "priority": 10
      }
      JSON
      payload    = JSON.parse(json)
      @execution = KeycloakAdmin::AuthenticationExecutionInfoRepresentation.from_hash(payload)
    end

    it "parses the id" do
      expect(@execution.id).to eq "exec-001"
    end

    it "parses the requirement" do
      expect(@execution.requirement).to eq "ALTERNATIVE"
    end

    it "parses the display_name" do
      expect(@execution.display_name).to eq "Cookie"
    end

    it "parses the alias" do
      expect(@execution.alias).to eq "cookie-alt"
    end

    it "parses the description" do
      expect(@execution.description).to eq "Cookie based authentication"
    end

    it "parses the requirement_choices" do
      expect(@execution.requirement_choices).to eq ["REQUIRED", "ALTERNATIVE", "DISABLED"]
    end

    it "parses configurable" do
      expect(@execution.configurable).to eq false
    end

    it "parses authentication_flow" do
      expect(@execution.authentication_flow).to eq false
    end

    it "parses the provider_id" do
      expect(@execution.provider_id).to eq "auth-cookie"
    end

    it "parses the authentication_config" do
      expect(@execution.authentication_config).to eq "config-123"
    end

    it "parses the flow_id" do
      expect(@execution.flow_id).to eq "flow-456"
    end

    it "parses level" do
      expect(@execution.level).to eq 0
    end

    it "parses index" do
      expect(@execution.index).to eq 1
    end

    it "parses priority" do
      expect(@execution.priority).to eq 10
    end

    it "returns nil for nil hash" do
      expect(KeycloakAdmin::AuthenticationExecutionInfoRepresentation.from_hash(nil)).to be_nil
    end
  end

  describe "#to_json" do
    it "converts to camelCase JSON" do
      exec                     = KeycloakAdmin::AuthenticationExecutionInfoRepresentation.new
      exec.id                  = "exec-001"
      exec.requirement         = "REQUIRED"
      exec.display_name        = "Cookie"
      exec.provider_id         = "auth-cookie"
      exec.authentication_flow = false
      exec.flow_id             = "flow-456"
      exec.level               = 0
      exec.index               = 1

      parsed = JSON.parse(exec.to_json)
      expect(parsed["id"]).to eq "exec-001"
      expect(parsed["requirement"]).to eq "REQUIRED"
      expect(parsed["displayName"]).to eq "Cookie"
      expect(parsed["providerId"]).to eq "auth-cookie"
      expect(parsed["authenticationFlow"]).to eq false
      expect(parsed["flowId"]).to eq "flow-456"
      expect(parsed["level"]).to eq 0
      expect(parsed["index"]).to eq 1
    end
  end
end
