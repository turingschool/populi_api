require "faraday"
require "faraday_middleware"
require "hashie"

require "populi_api/tasks"

module PopuliAPI
  class Connection
    include Tasks

    attr_reader :config, :_connection

    def initialize(url: nil, access_key: nil, log_requests: false, inject_connection: nil)
      if inject_connection.present?
        @_connection = inject_connection
        return self
      end

      @config = Hashie::Mash.new({
        url: url,
        access_key: access_key,
        log_requests: log_requests
      })
      @_connection = create_connection
    end

    def request(task:, params: {})
      _connection.post("", params.merge(task: task))
    end

    def request_body(task:, params: {})
      response = self.request(task: task, params: params)
      response.body
    end

    def method_missing(method_name, *args)
      task = normalize_task(method_name)

      raise_if_task_not_recognized task

      request_body(task: task, params: args.first || {})
    end

    private

    def create_connection
      Faraday.new(
        url: config.url,
        headers: { "Authorization" => config.access_key }
      ) do |builder|
        builder.request :url_encoded
        builder.response :mashify  # Convert to Hashie::Mash
        builder.response :xml      # Parse XML

        if config.log_requests
          builder.response :logger, nil, { bodies: false, log_level: :info }
        end
      end
    end
  end
end
