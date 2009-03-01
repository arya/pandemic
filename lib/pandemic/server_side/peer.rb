module Pandemic
  module ServerSide
    class Peer
      include Util
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
        debug("Trying to connect to peer")
        Thread.new do
          @outgoing_connection_mutex.synchronize do
            debug("Grabbed outgoing connection mutex")
            if !self.connected?
              debug("Not connected, attempting connection")
              begin
                @outgoing_connection = TCPSocket.new(@host, @port)          
              rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED # TODO: any other exceptions?
                debug("Connection timed out or refused")
                @outgoing_connection = nil
              else
                debug("Connection successful")
              end
              @outgoing_connection.puts("SERVER #{@server.signature}") if @outgoing_connection
            end
          end
        end
      end
    
      def disconnect
        debug("Disconnecting from peer")
        @outgoing_connection.close unless @outgoing_connection.nil? || @outgoing_connection.closed?
        @incoming_connection.close unless @incoming_connection.nil? || @outgoing_connection.closed?
      end
    
      def connected?
        @outgoing_connection && !@outgoing_connection.closed? # TODO: any other indication that it's open?
      end
    
      def client_request(request, body)
        debug("Sending client's request to peer")
        Thread.new do
          @outgoing_connection_mutex.synchronize do
            debug("Grabbed outgoing connection mutex") 
            if self.connected?
              debug("Sending client's request")
              @pending_requests[request.hash] = request
              @outgoing_connection.puts("PROCESS #{request.hash} #{body.size}")
              @outgoing_connection.write(body)
              debug("Finished sending client's request")
            end # TODO: else? fail silently? reconnect?
          end
        end
      end
    
      def incoming_connection=(conn)
        debug("Setting incoming connection")
        @incoming_connection_listener.kill if @incoming_connection_listener # kill the previous one
        @incoming_connection.close if @incoming_connection && @incoming_connection != conn

        @incoming_connection = conn
        self.connect
        @incoming_connection_listener = Thread.new do
          debug("Incoming connection thread started")
          while @server.running
            debug("Listening for incoming requests")
            request = @incoming_connection.gets
            if request.nil? # TODO: better way to detect close of connection?
              debug("Incoming connection request is nil")
              @incoming_connection = nil
              @outgoing_connection.close if @outgoing_connection
              @outgoing_connection = nil
              break
            else
              debug("Received incoming (#{request.strip})")
              handle_incoming_request(request) if request =~ /^PROCESS/
              handle_incoming_response(request) if request =~ /^RESPONSE/
            end
          end
        end
      
      end
    
      def handle_incoming_request(request)
        debug("Identified as request")
        if request.strip =~ /^PROCESS ([A-Za-z0-9]+) ([0-9]+)$/
          hash = $1
          size = $2.to_i
          debug("Incoming request: #{size} #{hash}")
          begin
            debug("Reading request body")
            request_body = @incoming_connection.read(size)
            debug("Finished reading request body")
          rescue EOFError, TruncatedDataError
            debug("Failed to read request body")
            # TODO: what to do here?
            return false
          end
          debug("Processing body")
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
          # when the incoming response was malformed
          # TODO: what to do here? 
        end
      end
    
    
      def process_request(hash, body)
        Thread.new do
          debug("Starting processing thread (#{hash})")
          response = @server.process(body)
          debug("Processing finished (#{hash})")
          @outgoing_connection_mutex.synchronize do
            debug( "Sending response (#{hash})")
            @outgoing_connection.puts("RESPONSE #{hash} #{response.size}")
            @outgoing_connection.write(response)
            debug( "Finished sending response (#{hash})")
          end
        end
      end
    
      def process_response(hash, body)
        Thread.new do # because this part can be blocking and we don't want to wait for the
          original_request = @pending_requests.delete(hash)
          original_request.add_response(body) if original_request
        end
      end
      
      def debug(msg)
        logger.debug("Peer #{@host}:#{@port}")  { msg }
      end
    end
  end
end