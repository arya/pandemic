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
            if request.nil? # better way to detect disconnect
              @connection.close
              @connection = nil
              break
            else
              @connection.puts(handle_request(request.strip)) # TODO: format it
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