module PopuliAPI
  class Error < StandardError; end
  class NoConnectionError < Error; end
  class MissingArgumentError < Error; end
  class TaskNotFoundError < Error; end

  class ServerError < Error
    @@code = nil

    attr_reader :response

    def initialize(message, response)
      super(message)
      @response = response
    end

    def code
      @@code
    end

    def self.from_code(code)
      PopuliAPI.const_get(class_name_from_code(code).to_sym)
    end

    def self.class_name_from_code(code)
      name = code.downcase.classify
      name.end_with?("Error") ? name : "#{name}Error"
    end
  end

  %w[
    AUTHENTICATION_ERROR
    UKNOWN_TASK
    BAD_PARAMETER
    LOCKED_OUT
    PERMISSIONS_ERROR
    OTHER_ERROR
  ].each do |error_code|
    error_class_name = ServerError.class_name_from_code(error_code)
    error_class = Class.new(ServerError)
    error_class.class_variable_set(:@@code, error_code)

    PopuliAPI.const_set(error_class_name, error_class)
  end
end

