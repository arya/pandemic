module Pandemic
  module ServerSide
    class Client
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
            while @server.running
              request = @connection.gets
              if request.nil? # TODO: better way to detect disconnect
                @connection.close
                @connection = nil
                break
              elsif request.strip! =~ /^([0-9]+)$/ # currently only asking for request size
                size = $1.to_i
                body = @connection.read(size)
                response = handle_request(body)
                @connection.puts(response.size)
                @connection.write(response)
              end
            end
            @server.client_closed(self)
          end
        end
        return self
      end
    
      def close
        @connection.close unless @connection.nil? || @connection.closed?
      end
    
      def handle_request(request)
        @server.handle_client_request(Request.new(request))
      end
    end
  end
end