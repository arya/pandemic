module Pandemic
  module ConnectionPool
    class TimedOutWaitingForConnectionException < Exception; end
    
    def initialize(options = {})
      @mutex = Monitor.new
      @queue = @mutex.new_cond
      @available = []
      @connections = []
      @max_connections = options[:max_connections] || 10
      @timeout = options[:timeout] || 3
    end
    
    def disconnect
      @mutex.synchronize do
        puts @available.inspect
        puts @connections.inspect
        @available.each do |conn|
          destroy_connection(conn)
          @connections.delete(conn)
        end
        @available = []
        while @connections.size > 0 && @queue.wait
          @available.each do |conn|
            destroy_connection(conn)
            @connections.delete(conn)
          end
          @available = []
        end
      end
    end
    
    def with_connection(&block)
      connection = nil
      begin
        connection = checkout
        block.call(connection)
      ensure
        checkin(connection) if connection
      end
    end
    
    private
    
    def checkout
      connection = nil
      @mutex.synchronize do
        loop do
          if @available.size > 0
            connection = @available.shift
            break
          elsif @connections.size < @max_connections && (connection = create_connection)
            @connections << connection
            break
          elsif @queue.wait(@timeout)
            next
          else
            raise TimedOutWaitingForConnectionException
          end
        end
      end  
      return connection
    end
    
    def checkin(connection)
      @mutex.synchronize do
        @available.push(connection)
        @queue.signal
      end
    end
    
  end
end