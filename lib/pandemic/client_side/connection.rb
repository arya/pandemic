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

      private
      def connect
        @socket = begin
          connection = TCPSocket.new(@host, @port)
          if connection && !connection.closed?
            connection.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if Socket.constants.include?('TCP_NODELAY')
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