module DM
  class Client < Base
    def initialize(connection, server)
      super()
      @connection = connection
      @server = server
    end
    
    def listen
      return if @connection.nil? # throw exception?
      @listener_thread.kill if @listener_thread
      @listener_thread = Thread.new do
        while true
          request = @connection.gets
          if request.nil? # better way to detect disconnect
            @connection = nil
            break
          else
            handle_request(request.strip)
          end
        end
      end
    end
    
    def handle_request(request)
      response = @server.handle_client_request(Request.new(request))
    end
  end
end