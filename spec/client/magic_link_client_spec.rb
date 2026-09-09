RSpec.describe KeycloakAdmin::MagicLinkClient do
  describe "#initialize" do
    let(:realm_name) { nil }

    before(:each) do
      @realm = KeycloakAdmin.realm(realm_name)
    end

    context "when realm_name is defined" do
      let(:realm_name) { "master" }

      it "does not raise any error" do
        expect { @realm.magic_links }.to_not raise_error
      end
    end

    context "when realm_name is not defined" do
      it "raises argument error" do
        expect { @realm.magic_links }.to raise_error(ArgumentError, "realm must be defined")
      end
    end
  end

  describe "#magic_link_url" do
    let(:realm_name) { "valid-realm" }

    it "returns the realm-rooted url, not the admin url" do
      expect(KeycloakAdmin.realm(realm_name).magic_links.magic_link_url).to eq "http://auth.service.io/auth/realms/valid-realm/magic-link"
    end
  end

  describe "#create" do
    let(:realm_name) { "valid-realm" }
    let(:response_body) { '{"user_id":"95985b21-d884-4bbd-b852-cb8cd365afc2","link":"http://auth.service.io/auth/realms/valid-realm/login-actions/action-token?key=abc","sent":false}' }
    let(:request) do
      request                    = KeycloakAdmin::MagicLinkRequestRepresentation.new
      request.email              = "jane@example.com"
      request.client_id          = "web-app"
      request.redirect_uri       = "https://app.example.com/login"
      request.expiration_seconds = 900
      request.update_password    = true
      request
    end

    before(:each) do
      @magic_link_client = KeycloakAdmin.realm(realm_name).magic_links
      stub_token_client
      @captured = {}
      allow_any_instance_of(RestClient::Resource).to receive(:post) do |_resource, payload, headers|
        @captured[:payload] = payload
        @captured[:headers] = headers
        response_body
      end
    end

    it "posts to the realm-rooted magic-link url with the configured rest client options" do
      rest_client_options = {timeout: 10}
      allow_any_instance_of(KeycloakAdmin::Configuration).to receive(:rest_client_options).and_return rest_client_options

      expect(RestClient::Resource).to receive(:new).with(
        "http://auth.service.io/auth/realms/valid-realm/magic-link", rest_client_options).and_call_original

      @magic_link_client.create(request)
    end

    it "authenticates with the admin bearer token" do
      @magic_link_client.create(request)
      expect(@captured[:headers][:Authorization]).to eq "Bearer test_access_token"
      expect(@captured[:headers][:content_type]).to eq :json
      expect(@captured[:headers][:accept]).to eq :json
    end

    it "sends exactly the plugin's snake_case keys with safe boolean defaults" do
      @magic_link_client.create(request)
      expect(JSON.parse(@captured[:payload])).to eq(
        "email"              => "jane@example.com",
        "client_id"          => "web-app",
        "redirect_uri"       => "https://app.example.com/login",
        "expiration_seconds" => 900,
        "force_create"       => false,
        "update_password"    => true,
        "update_profile"     => false,
        "send_email"         => false,
        "reusable"           => false,
        "remember_me"        => false
      )
    end

    it "does not camelize any key" do
      @magic_link_client.create(request)
      expect(JSON.parse(@captured[:payload]).keys.grep(/[A-Z]/)).to be_empty
    end

    it "lets a caller opt into a reusable link" do
      request.reusable = true
      @magic_link_client.create(request)
      expect(@captured[:payload]).to include '"reusable":true'
    end

    it "still sends reusable:false and force_create:false when a caller sets them to nil" do
      request.reusable     = nil
      request.force_create = nil
      @magic_link_client.create(request)
      expect(@captured[:payload]).to include '"reusable":false'
      expect(@captured[:payload]).to include '"force_create":false'
      parsed = JSON.parse(@captured[:payload])
      expect(parsed["reusable"]).to eq false
      expect(parsed["force_create"]).to eq false
    end

    it "accepts a username instead of an email" do
      request.email    = nil
      request.username = "jane"
      @magic_link_client.create(request)
      parsed = JSON.parse(@captured[:payload])
      expect(parsed["username"]).to eq "jane"
      expect(parsed).not_to have_key("email")
    end

    it "parses the response into a MagicLinkResponseRepresentation" do
      response = @magic_link_client.create(request)
      expect(response).to be_a(KeycloakAdmin::MagicLinkResponseRepresentation)
      expect(response.user_id).to eq "95985b21-d884-4bbd-b852-cb8cd365afc2"
      expect(response.link).to eq "http://auth.service.io/auth/realms/valid-realm/login-actions/action-token?key=abc"
      expect(response.sent).to eq false
    end

    it "raises argument error when the request is nil" do
      expect { @magic_link_client.create(nil) }.to raise_error(ArgumentError, "magic_link_request_representation must be defined")
    end

    it "raises argument error when the request is not a MagicLinkRequestRepresentation" do
      expect { @magic_link_client.create({}) }.to raise_error(ArgumentError, "magic_link_request_representation must be a MagicLinkRequestRepresentation")
      expect { @magic_link_client.create("email" => "jane@example.com") }.to raise_error(ArgumentError, "magic_link_request_representation must be a MagicLinkRequestRepresentation")
      expect(@captured).to be_empty
    end

    it "raises argument error when expiration_seconds is nil" do
      request.expiration_seconds = nil
      expect { @magic_link_client.create(request) }.to raise_error(ArgumentError, "expiration_seconds must be defined")
      expect(@captured).to be_empty
    end

    it "raises argument error when both email and username are nil" do
      request.email    = nil
      request.username = nil
      expect { @magic_link_client.create(request) }.to raise_error(ArgumentError, "email or username must be defined")
      expect(@captured).to be_empty
    end
  end
end
