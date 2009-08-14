module HttpReactor
  class RequestExecutionHandler
    import org.apache.http.protocol
    import org.apache.http.nio.protocol
    include HttpRequestExecutionHandler
    
    REQUEST_SENT       = "request-sent"
    RESPONSE_RECEIVED  = "response-received"
    
    def initialize(request_count)
      @request_count = request_count
    end
    
    def initalize_context(context, attachment)
      context.set_attribute(ExecutionContext.HTTP_TARGET_HOST, attachment);
    end
    
    def finalize_context(context)
      flag = context.get_attribute(RESPONSE_RECEIVED)
      @request_count.count_down() unless flag
    end
    
    def submit_request(context)
      target_host = context.get_attribute(ExecutionContext.HTTP_TARGET_HOST);
      flag = context.get_attribute(REQUEST_SENT);
      if flag.nil?
        # Stick some object into the context
        context.set_attribute(REQUEST_SENT, true);

        puts "--------------"
        puts "Sending request to #{target_host}"
        puts "--------------"

        org.apache.http.message.BasicHttpRequest.new("GET", "/")
      else
        # No new request to submit
      end
    end
     
    def handle_response(response, context)
      entity = response.entity
      begin
        content = org.apache.http.util.EntityUtils.toString(entity)

        puts "--------------"
        puts response.status_line
        puts "--------------"
        puts "Document length: #{content.length}"
        puts "--------------"
      rescue java.io.IOException => ex
        puts "I/O error: #{ex.message}"
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
    def connectionOpen(conn)
      puts "Connection open: #{conn}"
    end
    def connectionTimeout(conn)
      puts "Connection timed out: #{conn}"
    end
    def connectionClosed(conn)
      puts "Connection closed: #{conn}"
    end
    def fatalIOException(ex, onn)
      puts "I/O error: #{ex.message}"
    end
    def fatalProtocolException(ex, conn)
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
    
    def initialize(hosts=[], session_request_callback=SessionRequestCallback)
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
      request_count = java.util.concurrent.CountDownLatch.new(3);

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
        rescue InterruptedIOException => e
          puts "Interrupted"
        rescue IOException => e
          puts "I/O error: #{e.message}"
        end
        puts "Shutdown"
      end
      
      hosts.each do |host|
        io_reactor.connect(
          java.net.InetSocketAddress.new(host, 80), 
          nil, 
          HttpHost.new(host),
          session_request_callback.new(request_count)
        )
      end
      
      # reqs = [];
      #       reqs << io_reactor.connect(
      #         java.net.InetSocketAddress.new("www.yahoo.com", 80), 
      #         nil, 
      #         HttpHost.new("www.yahoo.com"),
      #         SessionRequestCallback.new(request_count)
      #       )
      #       reqs << io_reactor.connect(
      #         java.net.InetSocketAddress.new("www.google.com", 80), 
      #         nil,
      #         HttpHost.new("www.google.com"),
      #         SessionRequestCallback.new(request_count)
      #       )
      #       reqs << io_reactor.connect(
      #         java.net.InetSocketAddress.new("www.apache.org", 80), 
      #         nil,
      #         HttpHost.new("www.apache.org"),
      #         SessionRequestCallback.new(request_count)
      #       )
      
      puts "Awaiting completion of request execution"
      
      # Block until all connections signal
      # completion of the request execution
      request_count.await()

      puts "Shutting down I/O reactor"

      io_reactor.shutdown()

      puts "Done"
    end
    
  end
end