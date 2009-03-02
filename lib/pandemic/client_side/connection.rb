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
          connection.write("CLIENT\n")
          if !connection.closed? # TOODO: improve condition
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