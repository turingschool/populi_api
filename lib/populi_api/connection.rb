module PopuliAPI
  class Connection
    attr_reader :url, :auth_token

    def initialize(url, auth_token)
      @url = url
      @auth_token = auth_token
    end
  end
end
