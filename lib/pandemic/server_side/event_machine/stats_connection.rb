module Pandemic::ServerSide
  module EventMachine
    class StatsConnection
      def initialize(connection, &block)
        @block = block
        connection.delegate = self
        handle_data("", connection)
      end
      
      def buffer?(data)
        data !~ /\n/
      end
      
      def handle_data(data, connection)
        data = data.strip
        if data == "stats" || data.empty?
          connection.write(@block.call)
        else
          connection.close
        end
      end
    end
  end
end