module PopuliAPI
  class Error < StandardError; end
  class NoConnectionError < Error; end
  class MissingArgumentError < Error; end
  class TaskNotFoundError < Error; end
end

