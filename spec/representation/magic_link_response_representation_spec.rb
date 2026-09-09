# frozen_string_literal: true

RSpec.describe KeycloakAdmin::MagicLinkResponseRepresentation do
  describe ".from_hash" do
    it "reads the plugin's snake_case keys" do
      rep = described_class.from_hash(
        "user_id" => "95985b21-d884-4bbd-b852-cb8cd365afc2",
        "link"    => "http://auth.service.io/auth/realms/a_realm/login-actions/action-token?key=abc",
        "sent"    => false
      )

      expect(rep.user_id).to eq "95985b21-d884-4bbd-b852-cb8cd365afc2"
      expect(rep.link).to eq "http://auth.service.io/auth/realms/a_realm/login-actions/action-token?key=abc"
      expect(rep.sent).to eq false
      expect(rep).to be_a(described_class)
    end
  end

  describe "#to_json" do
    it "keeps the plugin's snake_case keys and round-trips through from_json" do
      rep         = described_class.new
      rep.user_id = "95985b21-d884-4bbd-b852-cb8cd365afc2"
      rep.link    = "http://auth.service.io/auth/realms/a_realm/login-actions/action-token?key=abc"
      rep.sent    = false

      json = rep.to_json
      expect(json).to eq '{"user_id":"95985b21-d884-4bbd-b852-cb8cd365afc2","link":"http://auth.service.io/auth/realms/a_realm/login-actions/action-token?key=abc","sent":false}'
      expect(json).not_to include("userId")

      round_trip = described_class.from_json(json)
      expect(round_trip.user_id).to eq rep.user_id
      expect(round_trip.link).to eq rep.link
      expect(round_trip.sent).to eq false
    end

    it "omits nil attributes" do
      rep      = described_class.new
      rep.link = "http://auth.service.io/x"

      expect(JSON.parse(rep.to_json)).to eq("link" => "http://auth.service.io/x")
    end
  end
end
