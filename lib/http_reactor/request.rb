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
    
    # A hash where you can put extra stuff that should travel along
    # with the request and be accessible in the response handler
    def extra
      @extra ||= {}
    end
  end
end