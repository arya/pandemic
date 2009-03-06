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
                request = @connection.gets
                t("read from client", true)
                
                if request.nil? # TODO: better way to detect disconnect
                  @connection.close
                  @connection = nil
                  break
                elsif request.strip! =~ /^([0-9]+)$/ # currently only asking for request size
                  size = $1.to_i
                  body = @connection.read(size)
                  
                  response = handle_request(body)
                  @connection.write("#{response.size}\n#{response}")
                  @connection.flush
                  t("finished writing to client")
                end
              end
            rescue DisconnectClient
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
    end
  end
end