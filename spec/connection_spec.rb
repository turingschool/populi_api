RSpec.describe PopuliAPI::Connection do
  let(:access_key) { "magnetosux" }
  let(:url) { "https://xmansion.populiweb.com/api/" }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:mock_api) do
    Faraday.new do |b|
      b.adapter(:test, stubs) do |stub|
        stub.post("/") do |env|
          fixture = env.request_body.match(/fixture=([^&]*)/)&.captures&.first
          status = fixture == "error.xml" ? 400 : 200
          [
            status,
            { "content-type": "text/xml;charset=UTF-8" },
            fixture(fixture || "success.xml")
          ]
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
        result = subject.request(task, fixture: "error.xml")

        expect(result.keys).to contain_exactly("error")
        expect(result["error"]["code"]).to eq("OTHER_ERROR")
      end
    end
  end

  context "#request!(task, params)" do
    it "like #request, but will raise an error if the response is not successful" do
      expect { subject.request!(task, params) }.to_not raise_error

      expect do
        subject.request!(task, fixture: "error.xml")
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
        subject.getPerson!(fixture: "error.xml")
      end.to raise_error(PopuliAPI::OtherError)
    end
  end

  context "pagination in #request and #request!" do
    let(:role_members_responses) do
      [
        instance_double(
          "Faraday::Response",
          body: parse_xml(fixture("get_role_members_page_1.xml")),
          success?: true
        ),
        instance_double(
          "Faraday::Response",
          body: parse_xml(fixture("get_role_members_page_2.xml")),
          success?: true
        )
      ]
    end

    let(:updated_enrollments_responses) do
      [
        instance_double(
          "Faraday::Response",
          body: parse_xml(fixture("get_updated_enrollment_offset_0.xml")),
          success?: true
        ),
        instance_double(
          "Faraday::Response",
          body: parse_xml(fixture("get_updated_enrollment_offset_10.xml")),
          success?: true
        )
      ]
    end

    let(:applications_responses) do
      [
        instance_double(
          "Faraday::Response",
          body: parse_xml(fixture("get_applications_offset_0.xml")),
          success?: true
        ),
        instance_double(
          "Faraday::Response",
          body: parse_xml(fixture("get_applications_offset_11.xml")),
          success?: true
        )
      ]
    end

    it "will automatically aggregate data from paginated responses" do
      paginating_task = "getRoleMembers"
      allow(subject).to receive(:request_raw)
        .with(paginating_task, { page: 1 })
        .and_return(role_members_responses[0])
      allow(subject).to receive(:request_raw)
        .with(paginating_task, { page: 2 })
        .and_return(role_members_responses[1])

      role_members = subject.getRoleMembers!
      expect(role_members[:response][:num_results]).to eq("35")
      expect(role_members[:response][:person].count).to eq(35)
      expect(role_members[:response][:person].last[:personID]).to eq("35")
    end

    it "works with endpoints that use offset as well" do
      paginating_task = "getUpdatedEnrollment"
      allow(subject).to receive(:request_raw)
        .with(paginating_task, { offset: 0 })
        .and_return(updated_enrollments_responses[0])
      allow(subject).to receive(:request_raw)
        .with(paginating_task, { offset: 10 })
        .and_return(updated_enrollments_responses[1])

      enrollments = subject.getUpdatedEnrollment!
      expect(enrollments[:response][:num_results]).to eq("13")
      expect(enrollments[:response][:enrollment].count).to eq(13)
      expect(enrollments[:response][:enrollment].last[:id]).to eq("13")
    end

    it "will correctly aggregate data from paginated responses using offset" do
      paginating_task = "getApplications"
      allow(subject).to receive(:request_raw)
        .with(paginating_task, { offset: 0 })
        .and_return(applications_responses[0])
      allow(subject).to receive(:request_raw)
        .with(paginating_task, { offset: 10 })
        .and_return(applications_responses[1])

      applications = subject.getApplications!
      expect(applications[:response][:num_results]).to eq("11")
      expect(applications[:response][:application].count).to eq(11)
      expect(applications[:response][:application].last[:id]).to eq("11")
    end

    it "returns early if a request returns error" do
      paginating_task = "getTaggedPeople"
      expect do
        subject.request!(paginating_task, fixture: "error.xml")
      end.to raise_error(PopuliAPI::OtherError)
    end
  end
end
