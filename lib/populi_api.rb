require "active_support"
require "active_support/core_ext/string/inflections"

require "populi_api/version"
require "populi_api/errors"
require "populi_api/connection"

module PopuliAPI
  class << self
    attr_reader :connection

    def connect(access_key: nil, url: nil)
      return @connection if @connection.present?

      raise MissingArgumentError.new("Must provide an API url") unless url.present?
      raise MissingArgumentError.new("Must provide an access_key") unless access_key.present?

      @connection = Connection.new(url: url, access_key: access_key)
    end

    def reset!
      @connection = nil
    end

    def method_missing(method_name, *args)
      raise NoConnectionError unless connection.present?

      connection.send(method_name, *args)
    end
  end
end
