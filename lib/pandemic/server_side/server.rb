module Pandemic
  module ServerSide
    class Server
      include Util
      class StopServer < Exception; end
      class << self
        def boot(handler)
          Config.load
          Process.setrlimit(Process::RLIMIT_NOFILE, 4096) # arbitrary high number of max file descriptors.
          server = self.new(handler)
          set_signal_traps(server)
          server.start.join
        end
      
        private
        def set_signal_traps(server)
          interrupt_tries = 0
          Signal.trap(Signal.list["INT"]) do
            interrupt_tries += 1
            if interrupt_tries == 1
              server.stop
            else
              exit
            end
          end
        end
      end
      attr_reader :host, :port, :running
      def initialize(handler)
        @running = true
        @host, @port = host_port(Config.bind_to)
        @peers = {}
        @clients = []
        @clients_mutex = Mutex.new
        @servers = Config.servers
        @servers.each do |peer|
          next if peer == Config.bind_to # not a peer, it's itself
          @peers[peer] = Peer.new(peer, self)
        end
        @handler = handler
      end
    
      def start
        @listener = TCPServer.new(@host, @port)
        @peers.values.each { |peer| peer.connect }
        @listener_thread = Thread.new do
          begin
            while @running
              conn = @listener.accept
              Thread.new(conn) { |c| handle_connection(c) }
            end
          rescue StopServer
            @listener.close if @listener
          end
        end
      end
    
      def stop
        @running = false
        @listener_thread.raise(StopServer)
        @peers.values.each { |p| p.disconnect }
        @clients.each {|c| c.close }
      end
    
      def handle_connection(connection)
        identification = connection.gets.strip
        if identification =~ /^SERVER ([a-zA-Z0-9.]+:[0-9]+)$/
          host, port = host_port($1)
          matching_peer = @peers.values.detect { |peer| [peer.host, peer.port] == [host, port] }
          matching_peer.incoming_connection = connection unless matching_peer.nil?
        elsif identification =~ /^CLIENT$/
          @clients_mutex.synchronize do
            @clients << Client.new(connection, self).listen
          end
        else
          connection.close # i dunno you
        end
      end
    
      def handle_client_request(request)
        map = @handler.map(request, connection_statuses)
        request.max_responses = @peers.values.select {|p| p.connected? }.size + 1
        map.each do |peer, body|
          if @peers[peer]
            Thread.new(@peers[peer], request, body) do |peer, request, body| 
              peer.client_request(request, body)
            end
          end
        end
        Thread.new { request.add_response(self.process(map[signature])) } if map[signature]
        request.wait_for_responses
        @handler.reduce(request)
      end
    
      def process(body)
        @handler.process(body)
      end
    
      def signature
        "#{@host}:#{@port}"
      end
      
      def connection_statuses
        @servers.inject({}) do |statuses, server|
          if server == signature
            statuses[server] = :self
          else
            statuses[server] = @peers[server].connected? ? :connected : :disconnected
          end
          statuses
        end
      end
      
      def client_closed(client)
        @clients_mutex.synchronize do
          @clients.delete(client)
        end
      end
    end
  end
end