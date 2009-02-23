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
        Thread.new do
          @outgoing_connection_mutex.synchronize do
            if !self.connected?
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
    
      def disconnect
        @outgoing_connection.close unless @outgoing_connection.nil? || @outgoing_connection.closed?
        @incoming_connection.close unless @incoming_connection.nil? || @outgoing_connection.closed?
      end
    
      def connected?
        @outgoing_connection && !@outgoing_connection.closed? # TODO: any other indication that it's open?
      end
    
      def client_request(request, body)
        Thread.new do
          @outgoing_connection_mutex.synchronize do
            if self.connected?
              @pending_requests[request.hash] = request
              @outgoing_connection.puts("PROCESS #{request.hash} #{body.size}")
              @outgoing_connection.write(body)
            end # TODO: else? fail silently? reconnect?
          end
        end
      end
    
      def incoming_connection=(conn)
        @incoming_connection_listener.kill if @incoming_connection_listener # kill the previous one
        @incoming_connection.close if @incoming_connection && @incoming_connection != conn

        @incoming_connection = conn
        self.connect
        @incoming_connection_listener = Thread.new do
          while @server.running
            request = @incoming_connection.gets
            if request.nil? # TODO: better way to detect close of connection?
              @incoming_connection = nil
              @outgoing_connection.close if @outgoing_connection
              @outgoing_connection = nil
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
          # when the incoming response was malformed
          # TODO: what to do here? 
        end
      end
    
    
      def process_request(hash, body)
        Thread.new do
          response = @server.process(body)
          @outgoing_connection_mutex.synchronize do
            @outgoing_connection.puts("RESPONSE #{hash} #{response.size}")
            @outgoing_connection.write(response)
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
end