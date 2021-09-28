require "faraday"
require "faraday_middleware"

require "populi_api/errors"
require "populi_api/middleware/indifferent_hashify"
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

    def request_raw(task, params = {})
      _connection.post("", params.merge(task: task))
    end

    def request(task, params = {})
      response = paginate_task?(task) \
        ? self.auto_paginate_requests(task, params) \
        : self.request_raw(task, params)

      response.body
    end

    def request!(task, params = {})
      response = paginate_task?(task) \
        ? self.auto_paginate_requests(task, params) \
        : self.request_raw(task, params)

      raise error_for(response) unless response.success?
      response.body
    end

    def method_missing(method_name, *args)
      task, do_raise = normalize_task(method_name)
      raise_if_task_not_recognized task

      params = args.first || {}
      method = do_raise ? :request! : :request
      self.send(method, task, params)
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

    def auto_paginate_requests(task, params = {})
      paginated_task = get_paginated_task(task)
      record_key_path = paginated_task.record_key_path
      page_or_offset = paginated_task.page_or_offset

      pagination_params = case page_or_offset
                          when :page
                            { page: 1 }
                          when :offset
                            { offset: 0 }
                          end

      main_response = curr_response = \
        self.request_raw(task, params.merge(pagination_params))
      return main_response if !main_response.success?

      total = main_response.body[:response][:num_results].to_i

      return main_response if total == 1

      loop do
        acc_records = main_response.body[:response].dig(*record_key_path)
        break if acc_records.nil? || total == acc_records.count

        unless curr_response.success?
          main_response = curr_response
          break
        end

        next_index = case page_or_offset
                     when :page
                       pagination_params[:page] + 1
                     when :offset
                       acc_records.count
                     end
        pagination_params = { page_or_offset => next_index }

        curr_response = self.request_raw(task, params.merge(pagination_params))
        records = curr_response.body[:response].dig(*record_key_path)

        if record_key_path.size == 1
          main_response.body[:response][record_key_path.first] = acc_records + records
        else
          path, key = record_key_path[0...-1], record_key_path.last
          main_response.body[:response].dig(*path)[key] = acc_records + records
        end
      end

      main_response
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
