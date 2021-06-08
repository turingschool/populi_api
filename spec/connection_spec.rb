RSpec.describe PopuliAPI::Connection do
  let(:access_key) { "magnetosux" }
  let(:url) { "https://xmansion.populiweb.com/api/" }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:mock_api) do
    Faraday.new do |b|
      b.adapter(:test, stubs)
      b.request :url_encoded
      b.response :mashify
      b.response :xml
    end
  end

  # use stubbed Faraday connection by default
  subject { PopuliAPI::Connection.new(inject_connection: mock_api) }

  context "#initialize(url:, access_key:)" do
    it "sets a URL and auth token" do
      conn = PopuliAPI::Connection.new(url: url, access_key: access_key)
      expect(conn.url).to eq(url)
      expect(conn.access_key).to eq(access_key)
    end

    it "establishes a connection with the proper URL and headers" do
      expect(Faraday).to receive(:new).with({
        url: url,
        headers: { "Authorization" => access_key }
      })

      PopuliAPI::Connection.new(url: url, access_key: access_key)
    end
  end

  context "#request(task:, params:)" do
    let(:task) { "getData" }
    let(:params) { { id: "3", resource: "foo" } }

    it "sends an HTTP Post request with the task & params in the body" do
      expect(mock_api).to receive(:post).with("", params.merge(task: task))

      subject.request(task: task, params: params)
    end

    it "returns a parsed XML response as a Hashie::Mash structure" do
      stubs.post('/') do |env|
        [
          200,
          { "Content-Type": "application/xml" },
          <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <response><result>SUCCESS</result></response>
          XML
        ]
      end

      response = subject.request(task: task, params: params)
      expect(response.body.response.result).to eq("SUCCESS")
    end
  end
end
