module DM
  class Peer < Base
    # this class is what the server uses to connect/represent other servers
    attr_reader :host, :port
    def initialize(addr, server)
      super()
      @host, @port = host_port(addr)
      @server = server
      @pending_requests = {}
      @outgoing_connection_mutex = Mutex.new
      @outgoing_connection = nil
      
    end
    
    def connect
      Thread.new do
        @outgoing_connection_mutex.synchronize do
          if @outgoing_connection.nil? # TODO: check to see if its closed/dead
            begin
              @outgoing_connection = TCPSocket.new(@host, @port)          
            rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED # TODO: any other exceptions?
              @outgoing_connection = nil
            end
            @outgoing_connection.puts("SERVER #{@server.signature}") if @outgoing_connection
          end
        end
      end
    end
    
    def client_request(request)
      Thread.new do
        @outgoing_connection_mutex.synchronize do
          if @outgoing_connection
            @outgoing_connection.puts("PROCESS #{request.signature}")
            @outgoing_connection.puts(request.body)
            @pending_requests[request.hash] = request
          end # TODO: else? fail silently? reconnect?
        end
      end
    end
    
    def incoming_connection=(conn)
      @incoming_connection_listener.kill if @incoming_connection_listener # kill the previous one

      @incoming_connection = conn
      self.connect
      @incoming_connection_listener = Thread.new do
        while true
          request = @incoming_connection.gets
          if request.nil? # TODO: better way to detect close of connection?
            @incoming_connection = nil
            @outgoing_connection.close if @outgoing_connection
            @outgoing_connection = nil
            puts "Lost incoming connection with #{@port}, closing outgoing"
            break
          else
            handle_incoming_request(request) if request =~ /^PROCESS/
            handle_incoming_response(request) if request =~ /^RESPONSE/
          end
        end
      end
      
    end
    
    def handle_incoming_request(request)
      if request.strip =~ /^PROCESS ([A-Za-z0-9]+) ([0-9]+)$/
        hash = $1
        size = $2.to_i
        begin
          request_body = @incoming_connection.read(size)
        rescue EOFError, TruncatedDataError
          # TODO: what to do here?
          return false
        end
        process_request(hash, request_body)
      else
        # when the incoming request was malformed
        # TODO: what to do here? 
      end
    end
    
    def handle_incoming_response(response)
      if response.strip =~ /^RESPONSE ([A-Za-z0-9]+) ([0-9]+)$/
        hash = $1
        size = $2.to_i
        begin
          response_body = @incoming_connection.read(size)
        rescue EOFError, TruncatedDataError
          # TODO: what to do here?
          return false
        end
        process_response(hash, response_body)
      else
        # when the incoming request was malformed
        # TODO: what to do here? 
      end
    end
    
    
    def process_request(hash, body)
      Thread.new do
        response = @server.process(body)
        @outgoing_connection_mutex.synchronize do
          @outgoing_connection.puts("RESPONSE #{hash} #{response.size}")
          @outgoing_connection.puts(response)
        end
      end
    end
    
    def process_response(hash, body)
      Thread.new do # because this part can be blocking and we don't want to wait for the
        original_request = @pending_requests.delete(hash)
        original_request.add_response(body) if original_request
      end
    end
    

  end
end