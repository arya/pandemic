module Pandemic
  module ClientSide
    class ClusterConnection
      class NotEnoughConnectionsTimeout < Exception; end
      class NoNodesAvailable < Exception; end
      class LostConnectionToNode < Exception; end
      
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
          begin
            socket.write("#{body.size}\n#{body}")
            response_size = socket.gets
            if response_size
              socket.read(response_size.strip.to_i)
            else
              # nil response size
              raise LostConnectionToNode
            end
          rescue Errno::ECONNRESET
            raise LostConnectionToNode
          end
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
        all_connections = key.nil? ? @connections : @grouped_connections[key]
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
            elsif (connection = create_connection(key)) && connection.alive?
              @connections << connection
              @grouped_connections[key] << connection
              break
            elsif all_connections.size > 0 && @queue.wait(Config.connection_wait_timeout)
              next
            else
              if all_connections.size > 0
                raise NotEnoughConnectionsTimeout
              else
                raise NoNodesAvailable
              end
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
        if key.nil?
          # find a key where we can add more connections
          min, min_key = nil, nil
          @grouped_connections.each do |key, list|
            if min.nil? || list.size < min
              min_key = key
              min = list.size
            end
          end
          key = min_key
        end
        return nil if @grouped_connections[key].size >= Config.max_connections_per_server
        host, port = host_port(Config.servers[key])
        Connection.new(host, port, key)
      end
      
      #TODO: a thread to manage killing and reviving connections
    end
  end
end