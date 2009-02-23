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
        @mutex = Mutex.new
        @connection_proxies = {}
        
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
          socket.puts(body.size)
          socket.write(body)
          
          response_size = socket.gets.strip.to_i
          socket.read(response_size)
        end
      end
      
      private
      def with_connection(key, &block)
        connection = nil
        begin
          connection = grab_connection(key)
          block.call(connection.socket)
        ensure
          return_connection(connection) if connection
        end
      end
      
      def grab_connection(key)
        connection = nil
        select_from = key.nil? ? @available : @grouped_available[key]
        @mutex.synchronize do
          if select_from.size > 0
            connection = select_from.pop
            if key.nil?
              @grouped_available[key].delete(connection)
            else
              @available.delete(connection)
            end
          elsif (connection = create_connection(key))
            @connections << connection
            @grouped_connections[key] << connection
          else
            #TODO: wait and try again then throw exception
          end
        end
        return connection
      end
      
      def return_connection(connection)
        @mutex.synchronize do
          @available.unshift(connection)
          @grouped_available[connection.key].unshift(connection)
        end
      end
      
      def create_connection(key)
        host, port = host_port(Config.servers[key])
        return nil if @grouped_connections[key].size >= Config.max_connections_per_server
        Connection.new(host, port, key)
      end
    end
  end
end