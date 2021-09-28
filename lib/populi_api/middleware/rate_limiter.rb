require "thread"
require "tzinfo"

# Rate limiter to prevent sending too many requests per second
# Implementation borrwed heavily from @sirupsen's https://github.com/sirupsen/airrecord
module PopuliAPI
  class RateLimiter < Faraday::Middleware

    # Rate limiting details taken from Populi's API docs
    # https://support.populiweb.com/hc/en-us/articles/223798787-API-Basics
    TIMEZONE = TZInfo::Timezone.get("US/Pacific")
    PEAK_HOURS = 3...19 # 3AM to 7PM
    PEAK_RPS = 50
    OFF_PEAK_RPS = 100

    DEFAULT_SLEEPER = ->(seconds) { sleep(seconds) }

    class << self
      attr_accessor :requests
    end

    attr_reader :sleeper, :mutex

    def initialize(app, sleeper: DEFAULT_SLEEPER)
      super(app)
      @sleeper = sleeper
      @mutex = Mutex.new
      clear
    end

    def call(env)
      mutex.synchronize do
        wait if delay_request?
        @app.call(env).on_complete do |_response_env|
          track_request
        end
      end
    end

    def track_request
      time = current_clocktime
      clear if requests.any? && (time - requests.last) > 1.0
      requests << time
      requests.shift if request_count > rps
    end

    def clear
      self.class.requests = []
    end

    def request_count
      requests.size
    end

    def requests_per_second
      return PEAK_RPS if PEAK_HOURS.member? current_hour_in_timezone

      OFF_PEAK_RPS
    end
    alias rps requests_per_second

    def delay_request?
      return false if requests.empty?
      return false unless request_count >= rps

      window_span < 1.0
    end

    private

    def requests
      self.class.requests
    end

    def wait
      # Time to wait until making the next request to stay within limits.
      # If span is negative, default to 0 (cannot sleep for negative seconds)
      wait_time = [1.0 - window_span, 0].max
      sleeper.call(wait_time)
    end

    # [1.1, 1.2, 1.3, 1.4, 1.5] => 1.5 - 1.1 => 0.4
    def window_span
      requests.last - requests.first
    end

    def current_clocktime
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def current_hour_in_timezone
      TIMEZONE.now.hour
    end
  end
end

Faraday::Request.register_middleware(
  populi_rate_limiter: PopuliAPI::RateLimiter
)
