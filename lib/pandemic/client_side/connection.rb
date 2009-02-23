module Pandemic
  module ClientSide
    class Connection
      attr_reader :key, :socket
      def initialize(host, port, key)
        @host, @port, @key = host, port, key
        connect
      end
      
      def alive?
        !!@socket
      end

      private
      def connect
        begin
          connection = TCPSocket.new(@host, @port)
          connection.puts("CLIENT")
          if !connection.closed? # TOODO: improve condition
            @socket = connection
          else
            nil
          end
          # TODO: add more timeout options/exception handling
        rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED
          nil
        end
      end
    end
  end
end