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

    def connect(auth_token: nil, school: nil)
      return @connection if @connection.present?

      raise MissingArgumentError.new("Must provide an auth_token") unless auth_token.present?
      raise MissingArgumentError.new("Must provide a school") unless school.present?

      @connection = Connection.new(build_url(school), auth_token)
    end

    def reset!
      @connection = nil
    end

    private def build_url(school)
      POPULI_API_DOMAIN.sub("{school}", school)
    end
  end
end
