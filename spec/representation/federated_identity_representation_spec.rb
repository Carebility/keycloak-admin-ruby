# frozen_string_literal: true

RSpec.describe KeycloakAdmin::FederatedIdentityRepresentation do
  describe ".from_hash" do
    it "converts the admin API's camelCase federated identity into class structure" do
      rep = described_class.from_hash(
        "identityProvider" => "google",
        "userId"           => "108204234903240",
        "userName"         => "jane@example.com"
      )

      expect(rep.identity_provider).to eq "google"
      expect(rep.user_id).to eq "108204234903240"
      expect(rep.user_name).to eq "jane@example.com"
      expect(rep).to be_a(described_class)
    end
  end

  describe "#to_json" do
    it "camelizes the attributes back to the admin API's names" do
      rep                   = described_class.new
      rep.identity_provider = "google"
      rep.user_id           = "108204234903240"
      rep.user_name         = "jane@example.com"
      expect(rep.to_json).to eq '{"identityProvider":"google","userId":"108204234903240","userName":"jane@example.com"}'
    end
  end
end
