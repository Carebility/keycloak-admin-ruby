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
end
