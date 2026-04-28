# frozen_string_literal: true

RSpec.describe KeycloakAdmin::ClientScopeRepresentation do
  describe ".from_hash" do
    it "converts hash response into class structure" do
      rep = described_class.from_hash(
        {
          "id" => "scope-id-1",
          "name" => "profile",
          "description" => "OpenID profile claims",
          "protocol" => "openid-connect",
          "attributes" => {
            "include.in.token.scope" => "true"
          },
          "protocolMappers" => [
            {
              "id" => "mapper-id-1",
              "name" => "email",
              "protocol" => "openid-connect",
              "protocolMapper" => "oidc-usermodel-property-mapper",
              "config" => {
                "claim.name" => "email",
                "user.attribute" => "email"
              }
            }
          ]
        }
      )

      expect(rep.id).to eq "scope-id-1"
      expect(rep.name).to eq "profile"
      expect(rep.description).to eq "OpenID profile claims"
      expect(rep.protocol).to eq "openid-connect"
      expect(rep.attributes["include.in.token.scope"]).to eq "true"
      expect(rep.protocol_mappers.length).to eq 1
      expect(rep.protocol_mappers.first).to be_a(KeycloakAdmin::ProtocolMapperRepresentation)
      expect(rep).to be_a(described_class)
    end
  end
end
