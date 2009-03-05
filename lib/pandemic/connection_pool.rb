module Pandemic
  class ConnectionPool
    class TimedOutWaitingForConnectionException < Exception; end
    class CreateConnectionUndefinedException < Exception; end
    include Util
    def initialize(options = {})
      @mutex = Monitor.new
      @queue = @mutex.new_cond
      @available = []
      @connections = []
      @max_connections = options[:max_connections] || 10
      @timeout = options[:timeout] || 3
    end
    
    def add_connection!
      # bang because we're ignorings the max connections
      conn = create_connection
      if conn
        @mutex.synchronize do
          @connections << conn
          @available << conn
        end
      end
    end
    
    def create_connection(&block)
      if block.nil?
        if @create_connection
          @create_connection.call
        else
          raise CreateConnectionUndefinedException.new("You must specify a block to create connections")
        end
      else
        @create_connection = block
      end
    end
    
    def destroy_connection(connection = nil, &block)
      if block.nil?
        if @destroy_connection
          @destroy_connection.call(connection)
        else
          if connection && !connection.closed?
            # defaul behavior is this
            connection.close
          end
        end
      else
        @destroy_connection = block
      end
    end
    
    def available?
      @mutex.synchronize { @available.size > 0 }
    end
    
    def available
      @mutex.synchronize { @available.size }
    end
    
    def size
      @mutex.synchronize { @connections.size }
    end
    
    def disconnect
      @mutex.synchronize do
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
            connection = @available.pop
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
        @available.unshift(connection)
        @queue.signal
      end
    end
    
  end
end