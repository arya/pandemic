module Pandemic
  module ServerSide
    class Peer
      class PeerUnavailableException < Exception; end
      include Util
      include ConnectionPool
      attr_reader :host, :port
      
      def initialize(addr, server)
        super()
        @host, @port = host_port(addr)
        @server = server
        @pending_requests = {}
        @incoming_connection_listeners = []
        @inc_threads_mutex = Mutex.new
      end
      
      def create_connection
        connection = nil
        begin
          connection = TCPSocket.new(@host, @port)
        rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED
          raise PeerUnavailableException
          connection = nil
        end
        connection.write("SERVER #{@server.signature}\n") if connection
        return connection
      end
      
      def destroy_connection(connection)
        connection.close if connection && !connection.closed?
      end
      
      def connect
        return if connected?
        begin
          with_connection {|c|}
        rescue PeerUnavailableException
        end
      end
      
      def connected?
        @available.size > 0
      end
    
      def client_request(request, body)
        debug("Sending client's request to peer")
        Thread.new do
          with_connection do |connection|
            if connection && !connection.closed?
              debug("Sending client's request")
              @pending_requests[request.hash] = request
              connection.write("PROCESS #{request.hash} #{body.size}\n#{body}")
              debug("Finished sending client's request")
            end # TODO: else? fail silently? reconnect?
          end
        end
      end
    
      def add_incoming_connection(conn)
        debug("Setting incoming connection")
        
        connect # if we're not connected, we should be
        
        thread = Thread.new(conn) do |connection|
          debug("Incoming connection thread started")
          begin
            while @server.running
              debug("Listening for incoming requests")
              request = connection.gets
              if request.nil? # TODO: better way to detect close of connection?
                debug("Incoming connection request is nil")
                break
              else
                debug("Received incoming (#{request.strip})")
                handle_incoming_request(request, connection) if request =~ /^PROCESS/
                handle_incoming_response(request, connection) if request =~ /^RESPONSE/
              end
            end
          ensure
            conn.close if conn && !conn.closed?
            @inc_threads_mutex.synchronize { @incoming_connection_listeners.delete(Thread.current)}
            if @incoming_connection_listeners.empty?
              disconnect
            end
          end
        end
        
        @inc_threads_mutex.synchronize {@incoming_connection_listeners.push(thread)}
      end
    
      def handle_incoming_request(request, connection)
        debug("Identified as request")
        if request.strip =~ /^PROCESS ([A-Za-z0-9]+) ([0-9]+)$/
          hash = $1
          size = $2.to_i
          debug("Incoming request: #{size} #{hash}")
          begin
            debug("Reading request body")
            request_body = connection.read(size)
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
    
      def handle_incoming_response(response, connection)
        if response.strip =~ /^RESPONSE ([A-Za-z0-9]+) ([0-9]+)$/
          hash = $1
          size = $2.to_i
          begin
            response_body = connection.read(size)
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
          with_connection do |connection|
            debug( "Sending response (#{hash})")
            connection.write("RESPONSE #{hash} #{response.size}\n#{response}")
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