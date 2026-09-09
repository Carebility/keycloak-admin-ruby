# frozen_string_literal: true

RSpec.describe KeycloakAdmin::MagicLinkRequestRepresentation do
  describe "#initialize" do
    it "defaults every boolean flag to false and leaves expiration_seconds unset" do
      request = described_class.new
      expect(request.force_create).to eq false
      expect(request.update_password).to eq false
      expect(request.update_profile).to eq false
      expect(request.send_email).to eq false
      expect(request.reusable).to eq false
      expect(request.remember_me).to eq false
      expect(request.expiration_seconds).to be_nil
      expect(request.email).to be_nil
      expect(request.username).to be_nil
    end
  end

  describe "#to_json" do
    it "serializes only the defaults when nothing else is set" do
      expect(described_class.new.to_json).to eq '{"force_create":false,"update_password":false,"update_profile":false,"send_email":false,"reusable":false,"remember_me":false}'
    end

    it "serializes every attribute under its snake_case name" do
      request                       = described_class.new
      request.email                 = "jane@example.com"
      request.username              = "jane"
      request.client_id             = "web-app"
      request.redirect_uri          = "https://app.example.com/login"
      request.expiration_seconds    = 259200
      request.force_create          = true
      request.update_password       = true
      request.update_profile        = true
      request.send_email            = true
      request.reusable              = true
      request.remember_me           = true
      request.scope                 = "openid"
      request.nonce                 = "n-0S6_WzA2Mj"
      request.state                 = "af0ifjsldkj"
      request.code_challenge        = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
      request.code_challenge_method = "S256"
      request.response_mode         = "query"

      expect(JSON.parse(request.to_json)).to eq(
        "email"                 => "jane@example.com",
        "username"              => "jane",
        "client_id"             => "web-app",
        "redirect_uri"          => "https://app.example.com/login",
        "expiration_seconds"    => 259200,
        "force_create"          => true,
        "update_password"       => true,
        "update_profile"        => true,
        "send_email"            => true,
        "reusable"              => true,
        "remember_me"           => true,
        "scope"                 => "openid",
        "nonce"                 => "n-0S6_WzA2Mj",
        "state"                 => "af0ifjsldkj",
        "code_challenge"        => "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
        "code_challenge_method" => "S256",
        "response_mode"         => "query"
      )
    end

    it "never emits a camelCase key (regression guard against CamelJson)" do
      request                       = described_class.new
      request.client_id             = "web-app"
      request.redirect_uri          = "https://app.example.com/login"
      request.expiration_seconds    = 900
      request.code_challenge_method = "S256"
      request.response_mode         = "query"

      keys = JSON.parse(request.to_json).keys
      expect(keys.grep(/[A-Z]/)).to be_empty
      expect(keys).to include("client_id", "redirect_uri", "expiration_seconds", "code_challenge_method", "response_mode")
      expect(request.to_json).not_to include("clientId", "redirectUri", "expirationSeconds")
    end

    it "omits nil attributes" do
      request       = described_class.new
      request.email = "jane@example.com"
      request.state = nil

      parsed = JSON.parse(request.to_json)
      expect(parsed).not_to have_key("username")
      expect(parsed).not_to have_key("state")
      expect(parsed).not_to have_key("expiration_seconds")
    end
  end

  describe ".from_hash" do
    it "reads the plugin's snake_case keys" do
      request = described_class.from_hash(
        "email"              => "jane@example.com",
        "client_id"          => "web-app",
        "redirect_uri"       => "https://app.example.com/login",
        "expiration_seconds" => 900,
        "reusable"           => true,
        "update_password"    => true
      )

      expect(request.email).to eq "jane@example.com"
      expect(request.client_id).to eq "web-app"
      expect(request.redirect_uri).to eq "https://app.example.com/login"
      expect(request.expiration_seconds).to eq 900
      expect(request.reusable).to eq true
      expect(request.update_password).to eq true
      expect(request).to be_a(described_class)
    end

    it "keeps the safe defaults for boolean flags that are absent" do
      request = described_class.from_hash("email" => "jane@example.com")

      expect(request.force_create).to eq false
      expect(request.update_password).to eq false
      expect(request.update_profile).to eq false
      expect(request.send_email).to eq false
      expect(request.reusable).to eq false
      expect(request.remember_me).to eq false
    end
  end
end
