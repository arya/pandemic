module Pandemic
  class Server < Base
    attr_reader :host, :port    
    def initialize(handler)
      @host, @port = host_port(Config.bind_to)
      @peers = {}
      @clients = []
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
      while true
        conn = @listener.accept
        Thread.new(conn) { |c| handle_connection(c) }
      end
    end
    
    def handle_connection(connection)
      identification = connection.gets.strip
      if identification =~ /^SERVER ([a-zA-Z0-9.]+:[0-9]+)$/
        host, port = host_port($1)
        matching_peer = @peers.values.detect { |peer| [peer.host, peer.port] == [host, port] }
        matching_peer.incoming_connection = connection unless matching_peer.nil?
      elsif identification =~ /^CLIENT$/
        @clients << Client.new(connection, self).listen
      else
        connection.close # i dunno you
      end
    end
    
    def handle_client_request(request)
      map = @handler.map(request, @servers)
      # TODO: should the map handle disconnected peers?
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
  end
end