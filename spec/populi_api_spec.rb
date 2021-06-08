RSpec.describe PopuliAPI do
  before { subject.reset! }

  it "has a version number" do
    expect(PopuliAPI::VERSION).not_to be nil
  end

  context "#connect(access_key:, school:)" do
    let(:access_key) { "magnetosux" }
    let(:school) { "xmansion" }

    it "requires an auth token and a school name" do
      expect do
        subject.connect(access_key: access_key, school: school)
      end.to_not raise_error

      subject.reset!

      expect do
        subject.connect(school: school)
      end.to raise_error(PopuliAPI::MissingArgumentError, "Must provide an access_key")

      subject.reset!

      expect do
        subject.connect(access_key: access_key)
      end.to raise_error(PopuliAPI::MissingArgumentError, "Must provide a school")
    end

    it "returns a new PopuliAPI::Connection instance with proper configuration" do
      subject.connect(access_key: access_key, school: school)

      expect(subject.connection.class).to be(PopuliAPI::Connection)
      expect(subject.connection.url).to eq("https://#{school}.populiweb.com/api/")
      expect(subject.connection.access_key).to eq(access_key)
    end

    it "is idempotent" do
      subject.connect(access_key: access_key, school: school)

      expect { subject.connect(access_key: "newtoken", school: "yaya") }.to_not \
        change { subject.connection }
    end
  end
end
