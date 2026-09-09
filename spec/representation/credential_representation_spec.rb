# frozen_string_literal: true

RSpec.describe KeycloakAdmin::CredentialRepresentation do
  describe ".from_hash" do
    it "converts the admin API's camelCase credential into class structure" do
      rep = described_class.from_hash(
        "id"             => "6f1b1c9e-2f3a-4d5b-8c7d-9e0f1a2b3c4d",
        "type"           => "password",
        "userLabel"      => "My password",
        "createdDate"    => 1757376000000,
        "secretData"     => "{\"value\":\"hashed\",\"salt\":\"c2FsdA==\"}",
        "credentialData" => "{\"hashIterations\":27500,\"algorithm\":\"pbkdf2-sha256\"}",
        "priority"       => 10,
        "temporary"      => false
      )

      expect(rep.id).to eq "6f1b1c9e-2f3a-4d5b-8c7d-9e0f1a2b3c4d"
      expect(rep.type).to eq "password"
      expect(rep.user_label).to eq "My password"
      expect(rep.created_date).to eq 1757376000000
      expect(rep.secret_data).to eq "{\"value\":\"hashed\",\"salt\":\"c2FsdA==\"}"
      expect(rep.credential_data).to eq "{\"hashIterations\":27500,\"algorithm\":\"pbkdf2-sha256\"}"
      expect(rep.priority).to eq 10
      expect(rep.temporary).to eq false
      expect(rep).to be_a(described_class)
    end

    it "still reads a client secret credential" do
      rep = described_class.from_hash("type" => "secret", "value" => "s3cr3t")
      expect(rep.type).to eq "secret"
      expect(rep.value).to eq "s3cr3t"
    end

    it "still reads the legacy hashed-password fields" do
      rep = described_class.from_hash(
        "type"              => "password",
        "algorithm"         => "bcrypt",
        "hashedSaltedValue" => "$2a$12$abc",
        "hashIterations"    => 12,
        "temporary"         => false
      )
      expect(rep.algorithm).to eq "bcrypt"
      expect(rep.hashedSaltedValue).to eq "$2a$12$abc"
      expect(rep.hashIterations).to eq 12
    end
  end

  describe ".from_password" do
    it "builds a password credential whose json is unchanged" do
      rep = described_class.from_password("acme0")
      expect(rep.type).to eq "password"
      expect(rep.value).to eq "acme0"
      expect(rep.temporary).to eq false
      expect(rep.to_json).to eq '{"value":"acme0","type":"password","temporary":false}'
    end

    it "honours the temporary flag" do
      expect(described_class.from_password("acme0", true).temporary).to eq true
    end
  end

  describe "#to_json" do
    it "camelizes the snake_case attributes back to the admin API's names" do
      rep              = described_class.new
      rep.user_label   = "My password"
      rep.created_date = 1757376000000
      expect(rep.to_json).to eq '{"userLabel":"My password","createdDate":1757376000000}'
    end
  end
end
