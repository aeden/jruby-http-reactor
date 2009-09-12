module HttpReactor
  # A class that represents an HTTP request.
  class Request
    attr_reader :uri, :method, :payload
    
    # Initialize the request object.
    def initialize(uri, method='GET', payload=nil)
      @uri = uri
      @method = method
      @payload = payload
    end
  end
end