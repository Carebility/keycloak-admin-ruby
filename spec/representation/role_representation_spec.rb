RSpec.describe KeycloakAdmin::RoleRepresentation do
  describe "#to_json" do
    before(:each) do
      @mapper = KeycloakAdmin::RoleRepresentation.from_hash(
        {
          "id" => "bb79fb10-a7b4-4728-a662-82a4de7844a3",
          "name" => "abcd",
          "composite" => true,
          "clientRole" => false
        }
      )
    end

    it "can convert to json with camelCased keys" do
      expect(JSON.parse(@mapper.to_json)).to eq(
        "id" => "bb79fb10-a7b4-4728-a662-82a4de7844a3",
        "name" => "abcd",
        "description" => nil,
        "scopeParamRequired" => nil,
        "composite" => true,
        "composites" => nil,
        "clientRole" => false,
        "containerId" => nil,
        "attributes" => nil
      )
    end
  end

  describe "array#to_json" do
    before(:each) do
      @mappers = [
        KeycloakAdmin::RoleRepresentation.from_hash(
          {
            "id" => "bb79fb10-a7b4-4728-a662-82a4de7844a3",
            "name" => "abcd",
            "composite" => true,
            "clientRole" => false
          }
        )
      ]
    end

    it "can convert an array to json with camelCased keys" do
      expect(JSON.parse(@mappers.to_json)).to eq(
        [
          {
            "id" => "bb79fb10-a7b4-4728-a662-82a4de7844a3",
            "name" => "abcd",
            "description" => nil,
            "scopeParamRequired" => nil,
            "composite" => true,
            "composites" => nil,
            "clientRole" => false,
            "containerId" => nil,
            "attributes" => nil
          }
        ]
      )
    end
  end
end
