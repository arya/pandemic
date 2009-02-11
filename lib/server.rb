module DM
  class Server < Base
    attr_reader :host, :port    
    def initialize(bind_to, peers)
      super()
      @host, @port = host_port(bind_to)
      @peers = []
      @clients = []
      peers.dup.each do |peer|
        next if peer == bind_to
        @peers << Peer.new(peer, self)
      end
    end
    
    def start
      @listener = TCPServer.new(@host, @port)
      @peers.each { |peer| peer.connect }
      while true
        conn = @listener.accept
        Thread.new(conn) { |c| handle_connection(c) }
      end
    end
    
    def handle_connection(connection)
      request = connection.gets.strip
      if request =~ /^SERVER ([a-zA-Z0-9.]+:[0-9]+)$/
        puts "#{@port}: handling server #{$1}"
        host, port = host_port($1)
        matching_peer = @peers.detect { |peer| [peer.host, peer.port] == [host, port] }
        matching_peer.incoming_connection = connection unless matching_peer.nil?
      elsif request =~ /^CLIENT$/
        puts "#{@port}: handling client"
        @clients << Client.new(connection, self).listen
      else
        connection.close # i dunno you
      end
    end
    
    def handle_client_request(request)
      # new threads to send to peers
      # new thread to send to self
      # sleep or and wake
      request.max_responses = @peers.size + 1 #
      @peers.each do |peer|
        Thread.new(peer) {|p| p.client_request(request) }
      end
      Thread.new { request.add_response(self.process(request.body)) }
      request.wait_for_responses
      request.responses
    end
    
    def process(body)
      "answer from #{@port}"
    end
    
    def signature
      "#{@host}:#{@port}"
    end
  end
end