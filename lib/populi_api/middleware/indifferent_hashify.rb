require "active_support/core_ext/hash/indifferent_access"

class Faraday::Response
  # Faraday response middleware to convert Hash structures
  # (generated by XML parser) into ActiveSupport::HashWithIndifferentAccess
  class IndifferentHashify < Faraday::Response::Middleware
    def parse(body)
      case body
      when Hash
        body.with_indifferent_access
      when Array
        body.map { |item| parse(item) }
      else
        body
      end
    end
  end

  register_middleware indifferent_hashify: IndifferentHashify
end

