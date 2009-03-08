module Pandemic
  module ServerSide
    class Client
      class DisconnectClient < Exception; end
      include Util
      def initialize(connection, server)
        super()
        @connection = connection
        @server = server
      end
    
      def listen
        unless @connection.nil?
          @listener_thread.kill if @listener_thread
          @listener_thread = Thread.new do
            begin
              while @server.running
                debug("Waiting for incoming request")
                request = @connection.gets
                info("Received incoming request")
                
                if request.nil? # TODO: better way to detect disconnect
                  debug("Incoming request is nil")
                  @connection.close
                  @connection = nil
                  break
                elsif request.strip! =~ /^([0-9]+)$/ # currently only asking for request size
                  size = $1.to_i
                  debug("Reading request body (size #{size})")
                  body = @connection.read(size)
                  debug("Finished reading request body")
                  
                  response = handle_request(body)
                  
                  debug("Writing response to client")
                  @connection.write("#{response.size}\n#{response}")
                  @connection.flush
                  debug("Finished writing response to client")
                end
              end
            rescue DisconnectClient
              info("Closing client connection")
              @connection.close unless @connection.nil? || @connection.closed?
            ensure
              @server.client_closed(self)
            end
          end
        end
        return self
      end
    
      def close
        @listener_thread.raise(DisconnectClient)
      end
    
      def handle_request(request)
        @server.handle_client_request(Request.new(request))
      end
      
      private
      def debug(msg)
        logger.debug("Client") {msg}
      end
      
      def info(msg)
        logger.info("Client") {msg}
      end
    end
  end
end