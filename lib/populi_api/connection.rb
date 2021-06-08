require "faraday"
require "faraday_middleware"
require "hashie"

module PopuliAPI
  class Connection
    attr_reader :url, :access_key, :_connection

    def initialize(url: nil, access_key: nil, inject_connection: nil)
      if inject_connection.present?
        @_connection = inject_connection
        return self
      end

      @url = url
      @access_key = access_key
      @_connection = create_connection
    end

    def request(task:, params: {})
      _connection.post("", params.merge(task: task))
    end

    private

    def create_connection
      Faraday.new(
        url: url,
        headers: { "Authorization" => access_key }
      ) do |builder|
        builder.request :url_encoded
        builder.response :mashify  # Convert to Hashie::Mash
        builder.response :xml      # Parse XML
        builder.response :logger, nil, { bodies: false, log_level: :info }
      end
    end
  end
end
