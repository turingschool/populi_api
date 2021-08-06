require "faraday"
require "faraday_middleware"

require "populi_api/errors"
require "populi_api/middleware"
require "populi_api/tasks"

module PopuliAPI
  class Connection
    include Tasks

    Config = Struct.new(:url, :access_key, :log_requests, keyword_init: true)

    FARADAY_BUILDER_CONFIG = Proc.new do |builder|
      builder.request :url_encoded
      builder.response :indifferent_hashify
      builder.response :xml # Parse XML
    end

    attr_reader :config, :_connection

    def initialize(url: nil, access_key: nil, log_requests: false, inject_connection: nil)
      if inject_connection.present?
        @_connection = inject_connection
        return self
      end

      @config = Config.new(
        url: url,
        access_key: access_key,
        log_requests: log_requests
      )
      @_connection = create_connection
    end

    def request_raw(task:, params: {})
      _connection.post("", params.merge(task: task))
    end

    def request(task:, params: {})
      response = self.request_raw(task: task, params: params)
      response.body
    end

    def request!(task:, params: {})
      response = self.request_raw(task: task, params: params)

      return response.body if response.success?

      raise error_for(response)
    end

    def method_missing(method_name, *args)
      task, do_raise = normalize_task(method_name)
      raise_if_task_not_recognized task

      method = do_raise ? :request! : :request
      self.send(method, { task: task, params: args.first || {} })
    end

    private

    def create_connection
      Faraday.new(
        url: config.url,
        headers: { "Authorization" => config.access_key }
      ) do |builder|
        FARADAY_BUILDER_CONFIG.call(builder)

        if config.log_requests
          builder.response :logger, nil, { bodies: false, log_level: :info }
        end
      end
    end

    def error_for(response)
      error_code = response.body&.dig("error", "code")
      error_message = response.body&.dig("error", "message")

      if error_code.present?
        ServerError.from_code(error_code).new(error_message, response)
      else
        ServerError.new("Failed response!", response)
      end
    end
  end
end
