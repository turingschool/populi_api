RSpec.describe PopuliAPI::Connection do
  let(:access_key) { "magnetosux" }
  let(:url) { "https://xmansion.populiweb.com/api/" }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:mock_api) do
    Faraday.new do |b|
      b.adapter(:test, stubs) do |stub|
        stub.post("/") do |env|
          [
            200,
            { "Content-Type": "application/xml" },
            <<~XML
              <?xml version="1.0" encoding="UTF-8"?>
              <response><result>SUCCESS</result></response>
            XML
          ]
        end
      end

      PopuliAPI::Connection::FARADAY_BUILDER_CONFIG.call(b)
    end
  end

  # use stubbed Faraday connection by default
  subject { PopuliAPI::Connection.new(inject_connection: mock_api) }

  context "#initialize(url:, access_key:)" do
    it "sets a URL and auth token" do
      conn = PopuliAPI::Connection.new(url: url, access_key: access_key)
      expect(conn.config.url).to eq(url)
      expect(conn.config.access_key).to eq(access_key)
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

    it "returns a parsed XML response as a Hash structure" do
      response = subject.request(task: task, params: params)
      expect(response.body.class).to eq(Hash)
      expect(response.body["response"]["result"]).to eq("SUCCESS")
      stubs.verify_stubbed_calls
    end
  end

  context "#request_body(task:, params:)" do
    let(:task) { "getData" }
    let(:params) { { id: "3", resource: "foo" } }

    it "wraps #request" do
      expect(subject).to receive(:request).with(task: task, params: params)
        .and_return(Hashie::Mash.new({ body: 'x' }))

      subject.request_body(task: task, params: params)
    end

    it "returns the request body, not the full request object" do
      result = subject.request_body(task: task, params: params)

      expect(result.keys).to contain_exactly("response")
      expect(result["response"]["result"]).to eq("SUCCESS")
    end
  end

  context "calling tasks as methods" do
    it "will convert tasks called as methods into #request_body() invocations" do
      expect(subject).to receive(:request_body)
        .with(task: "getPerson", params: { person_id: 1 })

      subject.get_person(person_id: 1)
    end

    it "allows methods to be called in either camelCase or snake_case format" do
      expect(subject).to receive(:request_body)
        .with(task: "getPerson", params: { person_id: 2 })
      subject.getPerson(person_id: 2)

      expect(subject).to receive(:request_body)
        .with(task: "getPerson", params: { person_id: 3 })
      subject.get_person(person_id: 3)
    end

    it "throws a TaskNotFoundError error if the task is not in the set of API_TASKS" do
      expect { subject.not_a_task(foo: "bar") }
        .to raise_error(PopuliAPI::TaskNotFoundError)
    end
  end
end
