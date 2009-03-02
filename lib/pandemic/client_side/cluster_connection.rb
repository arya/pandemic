module Pandemic
  module ClientSide
    class ClusterConnection
      include Util
      def initialize
        Config.load
        @connections = []
        @available = []
        @grouped_connections = Hash.new { |hash, key| hash[key] = [] }
        @grouped_available = Hash.new { |hash, key| hash[key] = [] }
        @mutex = Monitor.new
        @connection_proxies = {}
        @queue = @mutex.new_cond # TODO: there should be a queue for each group
        
        Config.servers.each_with_index do |server_addr, key|
          @connection_proxies[key] = ConnectionProxy.new(key, self)
          host, port = host_port(server_addr)
          Config.min_connections_per_server.times do
            connection = create_connection(key)
            if connection.alive?
              @connections << connection
              @available << connection
              @grouped_connections[key] << connection
              @grouped_available[key] << connection
            end
          end
        end
      end
      
      
      def [](key)
        @connection_proxies[key]
      end
      
      def request(body, key = nil)
        with_connection(key) do |socket|
          socket.write("#{body.size}\n#{body}")
          
          response_size = socket.gets.strip.to_i
          socket.read(response_size)
        end
      end
      
      private
      def with_connection(key, &block)
        connection = nil
        begin
          connection = checkout_connection(key)
          block.call(connection.socket)
        ensure
          checkin_connection(connection) if connection
        end
      end
      
      def checkout_connection(key)
        connection = nil
        select_from = key.nil? ? @available : @grouped_available[key]
        @mutex.synchronize do
          loop do
            if select_from.size > 0
              connection = select_from.pop
              if key.nil?
                @grouped_available[key].delete(connection)
              else
                @available.delete(connection)
              end
              break
            elsif (connection = create_connection(key))
              @connections << connection
              @grouped_connections[key] << connection
              break
            elsif @queue.wait(Config.connection_wait_timeout)
              next
            else
              raise "Timed out waiting for connection"
            end
          end
        end
        return connection
      end
      
      def checkin_connection(connection)
        @mutex.synchronize do
          @available.unshift(connection)
          @grouped_available[connection.key].unshift(connection)
          @queue.signal
        end
      end
      
      def create_connection(key)
        return nil if @grouped_connections[key].size >= Config.max_connections_per_server
        host, port = host_port(Config.servers[key])
        Connection.new(host, port, key)
      end
      
      #TODO: a thread to manage killing and reviving connections
    end
  end
end