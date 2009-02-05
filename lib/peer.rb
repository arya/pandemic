module DM
  class Peer < Base
    # this class is what the server uses to connect/represent other servers
    attr_reader :host, :port
    def initialize(addr, server)
      super()
      @host, @port = host_port(addr)
      @server = server
      @outgoing_connection_monitor = Monitor.new
      @outgoing_connection = nil
    end
    
    def connect
      Thread.new do
        @outgoing_connection_monitor.synchronize do
          if @outgoing_connection.nil?
            begin
              @outgoing_connection = TCPSocket.new(@host, @port)          
            rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED
              @outgoing_connection = nil
            end
            @outgoing_connection.puts("SERVER #{@server.signature}") if @outgoing_connection
          end
        end
      end
    end
    
    def client_request(request)
      Thread.new do
        @outgoing_connection_monitor.synchronize do
          if @outgoing_connection
            @outgoing_connection.puts("PROCESS #{request.body}")
            request.add_response(@outgoing_connection.gets.strip)
          end
        end
      end
    end
    
    def incoming_connection=(conn)
      @incoming_connection_listener.kill if @incoming_connection_listener #maybe not kill, maybe stop

      @incoming_connection = conn
      self.connect
      @incoming_connection_listener = Thread.new do
        while true
          request = @incoming_connection.gets
          if request.nil? # TODO: better way to detect close of connection?
            @incoming_connection = nil
            @outgoing_connection.close if @outgoing_connection
            @outgoing_connection = nil
            puts "Lost incoming connection with #{@port}, closing outgoing"
            break
          else
            handle_request(request.strip)
          end
        end
      end
    end
  end
end