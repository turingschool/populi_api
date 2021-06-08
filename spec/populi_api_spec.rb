RSpec.describe PopuliAPI do
  before { subject.reset! }

  it "has a version number" do
    expect(PopuliAPI::VERSION).not_to be nil
  end

  context "#connect" do
    let(:auth_token) { "magnetosux" }
    let(:school) { "xmansion" }

    it "requires an auth token and a school name" do
      expect do
        subject.connect(auth_token: auth_token, school: school)
      end.to_not raise_error

      subject.reset!

      expect do
        subject.connect(school: school)
      end.to raise_error(PopuliAPI::MissingArgumentError, "Must provide an auth_token")

      subject.reset!

      expect do
        subject.connect(auth_token: auth_token)
      end.to raise_error(PopuliAPI::MissingArgumentError, "Must provide a school")
    end

    it "returns a new PopuliAPI::Connection instance with proper configuration" do
      subject.connect(auth_token: auth_token, school: school)

      expect(subject.connection.class).to be(PopuliAPI::Connection)
      expect(subject.connection.url).to eq("https://#{school}.populiweb.com/api/")
      expect(subject.connection.auth_token).to eq(auth_token)
    end

    it "is idempotent" do
      subject.connect(auth_token: auth_token, school: school)

      expect { subject.connect(auth_token: "newtoken", school: "yaya") }.to_not \
        change { subject.connection }
    end
  end
end
