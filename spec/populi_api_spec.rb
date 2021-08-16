RSpec.describe PopuliAPI do
  it "has a version number" do
    expect(PopuliAPI::VERSION).not_to be nil
  end

  context "#connect(access_key:, url:)" do
    before { subject.reset! }

    let(:access_key) { "magnetosux" }
    let(:url) { "https://xmansion.populiweb.com/api/" }

    it "requires an auth token and a url name" do
      expect do
        subject.connect(access_key: access_key, url: url)
      end.to_not raise_error

      subject.reset!

      expect do
        subject.connect(url: url)
      end.to raise_error(PopuliAPI::MissingArgumentError, "Must provide an access_key")

      subject.reset!

      expect do
        subject.connect(access_key: access_key)
      end.to raise_error(PopuliAPI::MissingArgumentError, "Must provide an API url")
    end

    it "returns a new PopuliAPI::Connection instance with proper configuration" do
      subject.connect(access_key: access_key, url: url)

      expect(subject.connection.class).to be(PopuliAPI::Connection)
      expect(subject.connection.config.url).to eq(url)
      expect(subject.connection.config.access_key).to eq(access_key)
    end

    it "is idempotent" do
      subject.connect(access_key: access_key, url: url)

      expect { subject.connect(access_key: "newtoken", url: "http://foo.bar") }.to_not \
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
