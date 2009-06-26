module Pandemic
  module ClientSide
    class Connection
      attr_reader :key, :socket
      def initialize(host, port, key)
        @host, @port, @key = host, port, key
        connect
      end
      
      def alive?
        @socket && !@socket.closed?
      end
      
      def ensure_alive!
        connect unless self.alive?
      end
      
      def died!
        @socket.close if self.alive?
        @socket = nil
      end

      private
      def connect
        @socket = begin
          connection = TCPSocket.new(@host, @port)
          if connection && !connection.closed?
            connection.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if TCP_NO_DELAY_AVAILABLE
            connection.write("CLIENT\n")
            connection
          else
            nil
          end
        rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED
          nil
        end
      end
    end
  end
end