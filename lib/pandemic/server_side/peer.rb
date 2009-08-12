module Pandemic
  module ServerSide
    class Peer
      class PeerUnavailableException < StandardError; end
      include Util
      attr_reader :host, :port
      
      def initialize(addr, server)
        @host, @port = host_port(addr)
        @server = server
        @pending_requests = with_mutex({})
        @incoming_connection_listeners = []
        @inc_threads_mutex = Mutex.new
        initialize_connection_pool
      end
      
      def connect
        # debug("Forced connection to peer")
        @connection_pool.connect
      end
      
      def disconnect
        # debug("Disconnecting from peer")
        @connection_pool.disconnect
      end
      
      def connected?
        @connection_pool.connected?
      end
    
      def client_request(request, body)
        # debug("Sending client's request to peer")
        # debug("Connection pool has #{@connection_pool.available_count} of #{@connection_pool.connections_count} connections available")

        successful = true
        @pending_requests.synchronize do
          @pending_requests[request.hash] = request
        end
        begin
          @connection_pool.with_connection do |connection|
            if connection && !connection.closed?
              # debug("Writing client's request")
              connection.write("PROCESS #{request.hash} #{body.size}\n#{body}")
              connection.flush
              # debug("Finished writing client's request")
            else
              successful = false
            end
          end
        rescue Exception
          @pending_requests.synchronize { @pending_requests.delete(request.hash) }
          raise
        else
          if !successful
            @pending_requests.synchronize { @pending_requests.delete(request.hash) }
          end
        end
      end
    
      def add_incoming_connection(conn)
        # debug("Adding incoming connection")

        connect # if we're not connected, we should be

        
        thread = Thread.new(conn) do |connection|
          begin
            # debug("Incoming connection thread started")
            while @server.running
              # debug("Listening for incoming requests")
              request = connection.gets
              # debug("Read incoming request from peer")
              
              if request.nil?
                # debug("Incoming connection request is nil")
                break
              else
                # debug("Received incoming (#{request.strip})")
                handle_incoming_request(request, connection) if request =~ /^PROCESS/
                handle_incoming_response(request, connection) if request =~ /^RESPONSE/
              end
            end
          rescue Exception => e
            warn("Unhandled exception in peer listener thread:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          ensure
            # debug("Incoming connection closing")
            conn.close if conn && !conn.closed?
            @inc_threads_mutex.synchronize { @incoming_connection_listeners.delete(Thread.current)}
            if @incoming_connection_listeners.empty?
              disconnect
            end
          end
        end
        
        @inc_threads_mutex.synchronize {@incoming_connection_listeners.push(thread) if thread.alive? }
      end
    
      private
      def initialize_connection_pool
        return if @connection_pool
        @connection_pool = ConnectionPool.new(:connect_at_define => false)
        
        @connection_pool.create_connection do
          connection = nil
          retries = 0
          begin
            connection = TCPSocket.new(@host, @port)
          rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED => e
            connection = nil
            # debug("Connection timeout or refused: #{e.inspect}")
            if retries == 0
              # debug("Retrying connection")
              retries += 1
              sleep 0.01
              retry
            end
          rescue Exception => e
            warn("Unhandled exception in create connection block:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          end
          if connection
            connection.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if TCP_NO_DELAY_AVAILABLE
            connection.write("SERVER #{@server.signature}\n")
          end
          connection
        end
      end
    
      def handle_incoming_request(request, connection)
        # debug("Identified as request")
        if request.strip =~ /^PROCESS ([A-Za-z0-9]+) ([0-9]+)$/
          hash = $1
          size = $2.to_i
          # debug("Incoming request: #{hash} #{size}")
          begin
            # debug("Reading request body")
            request_body = connection.read(size)
            # debug("Finished reading request body")
          rescue EOFError, TruncatedDataError
            # debug("Failed to read request body")
            # TODO: what to do here?
            return false
          rescue Exception => e
            warn("Unhandled exception in incoming request read:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          end
          # debug("Processing body")
          process_request(hash, request_body)
        else
          warn("Malformed incoming request: #{request.strip}")
          # when the incoming request was malformed
          # TODO: what to do here? 
        end
      end
    
      def handle_incoming_response(response, connection)
        if response.strip =~ /^RESPONSE ([A-Za-z0-9]+) ([0-9]+)$/
          hash = $1
          size = $2.to_i
          # debug("Incoming response: #{hash} #{size}")
          begin
            # debug("Reading response body")
            response_body = connection.read(size)
            # debug("Finished reading response body")
          rescue EOFError, TruncatedDataError
            # debug("Failed to read response body")
            # TODO: what to do here?
            return false
          rescue Exception => e
            warn("Unhandled exception in incoming response read:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          end
          process_response(hash, response_body)
        else
          warn("Malformed incoming response: #{response.strip}")
          # when the incoming response was malformed
          # TODO: what to do here? 
        end
      end
    
    
      def process_request(hash, body)
        Thread.new do
          begin
            # debug("Starting processing thread (#{hash})")
            response = @server.process(body)
            # debug("Processing finished (#{hash})")
            @connection_pool.with_connection do |connection|
              # debug( "Sending response (#{hash})")
              connection.write("RESPONSE #{hash} #{response.size}\n#{response}")
              connection.flush
              # debug( "Finished sending response (#{hash})")
            end
          rescue Exception => e
            warn("Unhandled exception in process request thread:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          end
        end
      end
    
      def process_response(hash, body)
        Thread.new do
          begin
            # debug("Finding original request (#{hash})")
            original_request = @pending_requests.synchronize { @pending_requests.delete(hash) }
            if original_request
              # debug("Found original request, adding response")
              original_request.add_response(body) 
            else
              warn("Original response not found (#{hash})")
            end
          rescue Exception => e
            warn("Unhandled exception in process response thread:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          end
        end
      end
      
      def debug(msg)
        logger.debug("Peer #{@host}:#{@port}")  { msg }
      end
      
      def warn(msg)
        logger.warn("Peer #{@host}:#{@port}")  { msg }
      end
    end
  end
end