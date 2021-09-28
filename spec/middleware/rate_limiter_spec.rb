RSpec.describe PopuliAPI::RateLimiter do
  let!(:faraday_app) { double("app") }
  let!(:sleep_tracker) { double("tracker") }
  let!(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let!(:endpoint) { "/endpoint" }
  let!(:connection) do
    Faraday.new do |builder|
      builder.request :populi_rate_limiter,
        sleeper: -> (s) { sleep_tracker.sleep(s) }

      builder.adapter :test, stubs do |stub|
        stub.get(endpoint) { |env| [200, {}, "x"] }
      end
    end
  end

  let(:three_am) { PopuliAPI::RateLimiter::TIMEZONE.local_time(2000, 1, 1, 3, 0, 0) }
  let(:seven_pm) { PopuliAPI::RateLimiter::TIMEZONE.local_time(2000, 1, 1, 19, 0, 0) }

  subject { PopuliAPI::RateLimiter.new(faraday_app) }
  before { subject.clear }

  it "does not wait on a single request" do
    allow(sleep_tracker).to receive(:sleep)

    connection.get(endpoint)
    expect(sleep_tracker).to_not have_received(:sleep)
  end

  it "will wait if requests per second exceed limit" do
    allow(sleep_tracker).to receive(:sleep)

    subject.requests_per_second.times { connection.get(endpoint) }
    expect(sleep_tracker).to_not have_received(:sleep)

    connection.get(endpoint)
    expect(sleep_tracker).to have_received(:sleep).once
  end

  describe "#requests_per_second" do
    context "during peak hours (3AM to 7PM Pacific Standard Time)" do
      before { travel_to three_am.localtime }

      it "uses 50 requests per second" do
        expect(subject.requests_per_second).to eq(50)
      end
    end

    context "during off-peak hours (7AM to 3AM Pacific Standard Time)" do
      before { travel_to seven_pm.localtime }

      it "uses 100 requests per second between 7AM and 3AM Pacific Standard Time" do
        expect(subject.requests_per_second).to eq(100)
      end
    end
  end

  describe "#delay_request?" do
    context "during peak hours (3AM to 7PM Pacific Standard Time)" do
      before { travel_to three_am.localtime }

      it "is true when > 50 requests are made during peak hours" do
        expect(subject.delay_request?).to be(false)
        49.times { subject.track_request }

        expect { subject.track_request }.to \
          change { subject.delay_request? }.from(false).to(true)
      end
    end

    context "during off-peak hours (7AM to 3AM Pacific Standard Time)" do
      before { travel_to seven_pm.localtime }

      it "is true when > 100 requests are made during off-peak hours" do
        expect(subject.delay_request?).to be(false)
        99.times { subject.track_request }

        expect { subject.track_request }.to \
          change { subject.delay_request? }.from(false).to(true)
      end
    end
  end

  describe "#track_request" do
    def stub_clock_time(clock_time = 100.001)
      allow(Process).to receive(:clock_gettime).and_return(clock_time)
    end

    it "appends the current process clock time to the requests list" do
      stub_clock_time

      expect { subject.track_request }.to \
        change { subject.class.requests }.from([]).to([100.001])
    end

    it "never allows list to grow beyond the requests_per_second limit" do
      travel_to three_am.localtime

      expect(subject.request_count).to eq(0)
      84.times { subject.track_request }
      expect(subject.request_count).to eq(50)
    end

    it "clears the requests list if the most recent request was made more than 1 second ago" do
      stub_clock_time(99.0)

      23.times { subject.track_request }
      expect(subject.request_count).to eq(23)

      stub_clock_time(100.01)

      expect { subject.track_request }.to \
        change { subject.request_count }.from(23).to(1)
    end
  end
end
