RSpec.describe PopuliAPI::Connection do
  RETURN_ERROR = 'return_error'

  let(:access_key) { "magnetosux" }
  let(:url) { "https://xmansion.populiweb.com/api/" }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:mock_api) do
    Faraday.new do |b|
      b.adapter(:test, stubs) do |stub|
        stub.post("/") do |env|
          if env.request_body.include? RETURN_ERROR
            [
              400,
              { "content-type": "text/xml;charset=UTF-8" },
              <<~XML
                <?xml version="1.0" encoding="UTF-8"?>
                <error>
                  <code>OTHER_ERROR</code>
                  <message>This is an error message.</message>
                </error>
              XML
            ]
          else
            [
              200,
              { "content-type": "text/xml;charset=UTF-8" },
              <<~XML
                <?xml version="1.0" encoding="UTF-8"?>
                <response><result>SUCCESS</result></response>
              XML
            ]
          end
        end
      end

      PopuliAPI::Connection::FARADAY_BUILDER_CONFIG.call(b)
    end
  end

  let(:task) { "getData" }
  let(:params) { { id: "3", resource: "foo" } }

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

  context "#request_raw(task, params)" do
    it "sends an HTTP Post request with the task & params in the body" do
      expect(mock_api).to receive(:post).with("", params.merge(task: task))

      subject.request_raw(task, params)
    end

    it "returns a parsed XML response as a HashWithIndifferentAccess structure" do
      response = subject.request_raw(task, params)
      expect(response.body.class).to eq(ActiveSupport::HashWithIndifferentAccess)
      expect(response.body[:response][:result]).to eq("SUCCESS")
      stubs.verify_stubbed_calls
    end
  end

  context "#request(task, params)" do
    it "wraps #request_raw" do
      mock_response = double("response")
      allow(mock_response).to receive(:body).and_return({ result: "SUCCESS" })
      allow(subject).to receive(:request_raw).and_return(mock_response)

      subject.request(task, params)
      expect(subject).to have_received(:request_raw).with(task, params)
    end

    it "returns the request body, not the full request object" do
      result = subject.request(task, params)

      expect(result.keys).to contain_exactly("response")
      expect(result["response"]["result"]).to eq("SUCCESS")
    end

    context "when response returns an error" do
      it "returns the body without raising an error" do
        result = subject.request(RETURN_ERROR)

        expect(result.keys).to contain_exactly("error")
        expect(result["error"]["code"]).to eq("OTHER_ERROR")
      end
    end
  end

  context "#request!(task, params)" do
    it "like #request, but will raise an error if the response is not successful" do
      expect { subject.request!(task, params) }.to_not raise_error

      expect do
        subject.request!(RETURN_ERROR)
      end.to raise_error do |error|
        expect(error.class).to be(PopuliAPI::OtherError)
        expect(error.code).to eq("OTHER_ERROR")
        expect(error.message).to eq("This is an error message.")
        expect(error.response).to be_present
      end
    end
  end

  context "calling tasks as methods" do
    it "will convert tasks called as methods into #request() invocations" do
      expect(subject).to receive(:request)
        .with("getPerson", { person_id: 1 })

      subject.get_person(person_id: 1)
    end

    it "allows methods to be called in either camelCase or snake_case format" do
      expect(subject).to receive(:request)
        .with("getPerson", { person_id: 2 })
      subject.getPerson(person_id: 2)

      expect(subject).to receive(:request)
        .with("getPerson", { person_id: 3 })
      subject.get_person(person_id: 3)
    end

    it "allows methods to be called with params as hash or named arguments" do
      expect(subject).to receive(:request)
        .with("getPerson", { person_id: 2 })
      subject.getPerson({ person_id: 2 })

      expect(subject).to receive(:request)
        .with("getPerson", { person_id: 3 })
      subject.get_person(person_id: 3)
    end

    it "throws a TaskNotFoundError error if the task is not in the set of API_TASKS" do
      expect { subject.not_a_task(foo: "bar") }
        .to raise_error(PopuliAPI::TaskNotFoundError)
    end

    it "uses #request! instead of #request if ! suffix is appended" do
      expect(subject).to receive(:request!)
        .with("getPerson", { person_id: 2 })
      subject.getPerson!(person_id: 2)
    end

    it "throws errors if ! suffix is appended and server returns error" do
      expect do
        subject.getPerson!(person_id: RETURN_ERROR)
      end.to raise_error(PopuliAPI::OtherError)
    end
  end
end
