require "active_support"
require "active_support/core_ext/string/inflections"

require "populi_api/connection"
require "populi_api/version"

module PopuliAPI
  class Error < StandardError; end
  class MissingArgumentError < Error; end

  POPULI_API_DOMAIN = "https://{school}.populiweb.com/api/"

  class << self
    attr_reader :connection

    def connect(access_key: nil, school: nil)
      return @connection if @connection.present?

      raise MissingArgumentError.new("Must provide an access_key") unless access_key.present?
      raise MissingArgumentError.new("Must provide a school") unless school.present?

      @connection = Connection.new(url: build_url(school), access_key: access_key)
    end

    def reset!
      @connection = nil
    end

    private def build_url(school)
      POPULI_API_DOMAIN.sub("{school}", school)
    end
  end
end
