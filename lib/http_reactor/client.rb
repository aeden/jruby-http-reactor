module HttpReactor
  class RequestExecutionHandler
    import org.apache.http.protocol
    import org.apache.http.nio.protocol
    include HttpRequestExecutionHandler
    
    REQUEST_SENT       = "request-sent"
    RESPONSE_RECEIVED  = "response-received"
    
    HTTP_TARGET_PATH = 'http_target_path'
    
    def initialize(request_count)
      @request_count = request_count
    end
    
    def initalize_context(context, attachment)
      context.set_attribute(ExecutionContext.HTTP_TARGET_HOST, attachment[:host]);
      context.set_attribute(HTTP_TARGET_PATH, attachment[:path])
    end
    
    def finalize_context(context)
      flag = context.get_attribute(RESPONSE_RECEIVED)
      @request_count.count_down() unless flag
    end
    
    def submit_request(context)
      target_host = context.get_attribute(ExecutionContext.HTTP_TARGET_HOST);
      target_path = context.get_attribute(HTTP_TARGET_PATH)
      flag = context.get_attribute(REQUEST_SENT);
      if flag.nil?
        # Stick some object into the context
        context.set_attribute(REQUEST_SENT, true);

        puts "--------------"
        puts "Sending request to #{target_host}#{target_path}"
        puts "--------------"

        org.apache.http.message.BasicHttpRequest.new("GET", target_path)
      else
        # No new request to submit
      end
    end
     
    def handle_response(response, context)
      target_host = context.get_attribute(ExecutionContext.HTTP_TARGET_HOST);
      target_path = context.get_attribute(HTTP_TARGET_PATH)
      
      entity = response.entity
      begin
        content = org.apache.http.util.EntityUtils.toString(entity)

        puts "--------------"
        puts "Response from #{target_host}#{target_path}"
        puts "--------------"
        puts response.status_line
        puts "--------------"
        puts "Document length: #{content.length}"
        puts "--------------"
      rescue java.io.IOException => ex
        puts "I/O error in handle_response: #{ex.message}"
      end

      context.setAttribute(RESPONSE_RECEIVED, true)

      # Signal completion of the request execution
      @request_count.count_down()
    end
  end
  
  class SessionRequestCallback
    include org.apache.http.nio.reactor.SessionRequestCallback
    
    def initialize(request_count)
      @request_count = request_count
    end

    def cancelled(request)
      puts "Connect request cancelled: #{request.remote_address}"
      @request_count.count_down()
    end

    def completed(request); end

    def failed(request)
      puts "Connect request failed: #{request.remote_address}"
      @request_count.count_down()
    end
    
    def timeout(request)
      puts "Connect request timed out: #{request.remote_address}"
      @request_count.count_down()
    end
  end
  
  class EventLogger
    import org.apache.http.nio.protocol
    include EventListener
    def connection_open(conn)
      puts "Connection open: #{conn}"
    end
    def connection_timeout(conn)
      puts "Connection timed out: #{conn}"
    end
    def connection_closed(conn)
      puts "Connection closed: #{conn}"
    end
    def fatalIOException(ex, onn)
      puts "Fatal I/O error: #{ex.message}"
    end
    def fatal_protocol_exception(ex, conn)
      puts "HTTP error: #{ex.message}"
    end
  end
  
  class Client
    import org.apache.http
    import org.apache.http.params
    import org.apache.http.protocol
    import org.apache.http.nio.protocol
    import org.apache.http.impl.nio
    import org.apache.http.impl.nio.reactor
    
    # Create a new HttpReactor client that will request the given URIs.
    def initialize(uris=[], session_request_callback=SessionRequestCallback)
      params = BasicHttpParams.new
      params.set_int_parameter(CoreConnectionPNames.SO_TIMEOUT, 5000)
      params.set_int_parameter(CoreConnectionPNames.CONNECTION_TIMEOUT, 10000)
      params.set_int_parameter(CoreConnectionPNames.SOCKET_BUFFER_SIZE, 8 * 1024)
      params.set_boolean_parameter(CoreConnectionPNames.STALE_CONNECTION_CHECK, false)
      params.set_boolean_parameter(CoreConnectionPNames.TCP_NODELAY, true)
      params.set_parameter(CoreProtocolPNames.USER_AGENT, "HttpComponents/1.1")
      
      io_reactor = DefaultConnectingIOReactor.new(2, params);
      
      httpproc = BasicHttpProcessor.new;
      httpproc.add_interceptor(RequestContent.new);
      httpproc.add_interceptor(RequestTargetHost.new);
      httpproc.add_interceptor(RequestConnControl.new);
      httpproc.add_interceptor(RequestUserAgent.new);
      httpproc.add_interceptor(RequestExpectContinue.new);
      
      # We are going to use this object to synchronize between the 
      # I/O event and main threads
      request_count = java.util.concurrent.CountDownLatch.new(uris.length);

      handler = BufferingHttpClientHandler.new(
        httpproc,
        RequestExecutionHandler.new(request_count),
        org.apache.http.impl.DefaultConnectionReuseStrategy.new,
        params
      )
       
      handler.event_listener = EventLogger.new
      
      io_event_dispatch = DefaultClientIOEventDispatch.new(handler, params)

      Thread.abort_on_exception = true
      t = Thread.new do
        begin
          puts "Executing IO reactor"
          io_reactor.execute(io_event_dispatch)
        rescue java.io.InterruptedIOException => e
          puts "Interrupted"
        rescue java.io.IOException => e
          puts "I/O error in reactor execution thread: #{e.message}"
        end
        puts "Shutdown"
      end
      
      uris.each do |uri|
        io_reactor.connect(
          java.net.InetSocketAddress.new(uri.host, uri.port), 
          nil, 
          {:host => HttpHost.new(uri.host), :path => uri.path},
          session_request_callback.new(request_count)
        )
      end
      
      # Block until all connections signal
      # completion of the request execution
      request_count.await()

      puts "Shutting down I/O reactor"

      io_reactor.shutdown()

      puts "Done"
    end
    
  end
end