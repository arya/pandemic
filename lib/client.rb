module DM
  class Client < Base
    def initialize(connection, server)
      super()
      @connection = connection
      @server = server
    end
    
    def listen
      unless @connection.nil?
        @listener_thread.kill if @listener_thread
        @listener_thread = Thread.new do
          while true
            request = @connection.gets
            if request.nil? # TODO: better way to detect disconnect
              @connection.close
              @connection = nil
              break
            elsif request =~ /^([0-9]+)$/ # currently only asking for request size
              size = $1.to_i
              body = @connection.read(size)
              response = handle_request(body)
              @connection.puts(response.size)
              @connection.write(response)
            end
          end
        end
      end
      return self
    end
    
    def handle_request(request)
      @server.handle_client_request(Request.new(request))
    end
  end
end