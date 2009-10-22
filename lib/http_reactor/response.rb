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
    
    def code
      status_line.status_code
    end
    
    # Get the response content type
    def content_type
      @content_type ||= @response_impl.entity.content_type.value
    end
    
    # Get the response content length
    def content_length
      @content_length ||= @response_impl.entity.content_length
    end
    
    # Access the headers
    def [](name)
      headers[name]
    end
    
    def headers
      @headers ||= begin
        h = Hash.new
        @response_impl.all_headers.each do |header|
          if h[header.name]
            h[header.name] = [h[header.name], header.value]
          else
            h[header.name] = header.value
          end
        end
        h
      end
    end
    
    # Get the body text
    def body
      @body ||= begin
        begin
          io = Java.java_to_ruby(
            org.jruby.RubyIO.new(JRuby.runtime, entity.content).java_object
          )
          io.read
        rescue Exception => e
          puts "Error in Response#body: #{e.message}"
        end
      end
    end
  end
end