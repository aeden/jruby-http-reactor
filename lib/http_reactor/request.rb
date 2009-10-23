module HttpReactor
  # A class that represents an HTTP request.
  class Request
    attr_accessor :uri
    attr_reader :method, :payload
    attr_accessor :extra
    
    # Initialize the request object.
    def initialize(uri, method='GET', payload=nil, extra={})
      @uri = uri
      @method = method
      @payload = payload
      @extra = extra
    end
    
    def [](name)
      headers[name]
    end
    
    def []=(name, value)
      headers[name] = value
    end
    
    def headers
      @headers ||= Hash.new
    end
  end
end