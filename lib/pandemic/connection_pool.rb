module Pandemic
  class ConnectionPool
    class TimedOutWaitingForConnectionException < Exception; end
    class CreateConnectionUndefinedException < Exception; end
    include Util
    def initialize(options = {})
      @connected = false
      @mutex = Monitor.new
      @queue = @mutex.new_cond
      @available = []
      @connections = []
      @max_connections = options[:max_connections] || 10
      @min_connections = options[:min_connections] || 1
      @timeout = options[:timeout] || 3
    end
    
    def add_connection!
      # bang because we're ignoring the max connections
      @mutex.synchronize do
        conn = create_connection
        @available << conn if conn && !conn.closed?
      end
    end
    
    def create_connection(&block)
      if block.nil?
        if @create_connection
          conn = @create_connection.call
          if conn && !conn.closed?
            @connections << conn
            @connected = true 
            conn
          end
        else
          raise CreateConnectionUndefinedException.new("You must specify a block to create connections")
        end
      else
        @create_connection = block
        connect
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
        @connections.delete(connection)
        # this is within the mutex of the caller
        @connected = false if @connections.empty?
      else
        @destroy_connection = block
      end
    end
    
    def connected?
      @connected
    end
    
    def connect
      @min_connections.times { add_connection! } if !connected?
    end
    
    def disconnect
      @mutex.synchronize do
        return if @disconnecting
        @disconnecting = true
        @connected = false # we don't want anyone thinking they can use this connection
        @available.each do |conn|
          destroy_connection(conn)
        end
        @available = []
        while @connections.size > 0 && @queue.wait
          @available.each do |conn|
            destroy_connection(conn)
          end
          @available = []
        end
        @disconnecting = false
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