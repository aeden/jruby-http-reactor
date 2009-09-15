module HttpReactor #:nodoc:
  # A class that represents an HTTP response which wraps the 
  # Java HTTP NIO response object and provides methods for accessing
  # the data using ruby idioms.
  class Response
    def initialize(response_impl)
      @response_impl = response_impl
    end
    
    # Delegates to the HTTP NIO response
    def status_line
      @response_impl.status_line
    end
    
    # Delegates to the HTTP NIO response
    def entity
      @response_impl.entity
    end
    
    # Get the response content type
    def content_type
      @response_impl.entity.content_type
    end
    
    # Get the response content length
    def content_length
      @response_impl.entity.content_length
    end
    
    # Get the body text
    def body
      begin
        entity = @response_impl.entity
        content_stream = entity.content
        io = Java.java_to_ruby(org.jruby.RubyIO.new(JRuby.runtime, content_stream).java_object)
        io.read
      rescue Exception => e
        puts "Error in Response#body: #{e.message}"
      end
    end
  end
end