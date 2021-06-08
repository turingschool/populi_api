RSpec.describe PopuliAPI do
  it "has a version number" do
    expect(PopuliAPI::VERSION).not_to be nil
  end

  context "#connect(access_key:, school:)" do
    before { subject.reset! }

    let(:access_key) { "magnetosux" }
    let(:school) { "xmansion" }

    it "requires an auth token and a school name" do
      expect do
        subject.connect(access_key: access_key, school: school)
      end.to_not raise_error

      # subject.reset! # make it fail!

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
      expect(subject.connection.config.url).to eq("https://#{school}.populiweb.com/api/")
      expect(subject.connection.config.access_key).to eq(access_key)
    end

    it "is idempotent" do
      subject.connect(access_key: access_key, school: school)

      expect { subject.connect(access_key: "newtoken", school: "yaya") }.to_not \
        change { subject.connection }
    end
  end

  context "task methods" do
    let(:stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:mock_api) { Faraday.new { |b| b.adapter(:test, stubs) } }

    before do
      mock_connection = PopuliAPI::Connection.new(inject_connection: mock_api)
      subject.instance_variable_set(:@connection, mock_connection)
    end

    it "delegates task methods to :connection" do
      expect(subject.connection).to receive(:get_person).with(person_id: 1)

      subject.get_person(person_id: 1)
    end
  end
end
