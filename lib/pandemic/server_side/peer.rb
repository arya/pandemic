module Pandemic
  module ServerSide
    class Peer
      class PeerUnavailableException < Exception; end
      include Util
      attr_reader :host, :port
      
      def initialize(addr, server)
        super()
        @host, @port = host_port(addr)
        @server = server
        @pending_requests = with_mutex({})
        @incoming_connection_listeners = []
        @inc_threads_mutex = Mutex.new
        initialize_connection_pool
      end
      
      def connect
        return if connected?
        10.times { @connection_pool.add_connection! }
      end
      
      def disconnect
        @connection_pool.disconnect
      end
      
      def connected?
        @connection_pool.connected?
      end
    
      def client_request(request, body)
        t("client request")
        debug("Sending client's request to peer")
        # TODO: Consider adding back threads here if it will be faster that way in Ruby 1.9
        @connection_pool.with_connection do |connection|
          t("thread started")
          if connection && !connection.closed?
            debug("Sending client's request")
            t("starting req sync")
            @pending_requests.synchronize do
              @pending_requests[request.hash] = request
            end
            t("writing")
            connection.write("PROCESS #{request.hash} #{body.size}\n#{body}")
            connection.flush
            t("done writing #{Time.now.to_f}")
            debug("Finished sending client's request")
          end # TODO: else? fail silently? reconnect?
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
              t("at incoming reader")
              IO.select([connection])
              request = connection.gets

              t("read from peer #{Time.now.to_f}")
              if request.nil? # TODO: better way to detect close of connection?
                debug("Incoming connection request is nil")
                break
              else
                t("choosing which handler")
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
        
        @inc_threads_mutex.synchronize {@incoming_connection_listeners.push(thread) if thread.alive? }
      end
    
      private
      def initialize_connection_pool
        return if @connection_pool
        @connection_pool = ConnectionPool.new
        
        @connection_pool.create_connection do
          connection = nil
          begin
            connection = TCPSocket.new(@host, @port)
          rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED
            connection = nil
          end
          connection.write("SERVER #{@server.signature}\n") if connection
          connection
        end
        
      end
    
      def handle_incoming_request(request, connection)
        debug("Identified as request")
        if request.strip =~ /^PROCESS ([A-Za-z0-9]+) ([0-9]+)$/
          hash = $1
          size = $2.to_i
          debug("Incoming request: #{size} #{hash}")
          t("about to read body")
          begin
            debug("Reading request body")
            request_body = connection.read(size)
            t("finished reading body")
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
        t("chose response handler")
        if response.strip =~ /^RESPONSE ([A-Za-z0-9]+) ([0-9]+)$/
          hash = $1
          size = $2.to_i
          begin
            t("about to read body")
            response_body = connection.read(size)
            t("read body")
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
        t("about to start process request thread")
        Thread.new do
          t("process request thread started")
          debug("Starting processing thread (#{hash})")
          response = @server.process(body)
          t("finished handler process")
          debug("Processing finished (#{hash})")
          @connection_pool.with_connection do |connection|
            t("about to write")
            debug( "Sending response (#{hash})")
            connection.write("RESPONSE #{hash} #{response.size}\n#{response}")
            connection.flush
            t("finished writing #{Time.now.to_f}")
            debug( "Finished sending response (#{hash})")
          end
        end
      end
    
      def process_response(hash, body)
        t("about to start thread to handle response")
        Thread.new do # because this part can be blocking and we don't want to wait for the
          t("thread to add response started")
          original_request = @pending_requests.synchronize { @pending_requests.delete(hash) }
          t("about to add response")
          original_request.add_response(body) if original_request
          t("finished adding response")
        end
      end
      
      def debug(msg)
        logger.debug("Peer #{@host}:#{@port}")  { msg }
      end
    end
  end
end