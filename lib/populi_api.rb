require "active_support"
require "active_support/core_ext/string/inflections"

require "populi_api/version"
require "populi_api/errors"
require "populi_api/connection"

module PopuliAPI
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

    def method_missing(method_name, *args)
      raise NoConnectionError unless connection.present?

      connection.send(method_name, *args)
    end

    private def build_url(school)
      POPULI_API_DOMAIN.sub("{school}", school)
    end
  end
end
