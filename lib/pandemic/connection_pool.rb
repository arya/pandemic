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
      @connect_at_define = options.include?(:connect_at_define) ? options[:connect_at_define] : true
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
        connect if @connect_at_define
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
        @available.delete(connection)
        # this is within the mutex of the caller
        @connected = false if @connections.empty?
      else
        @destroy_connection = block
      end
    end
    
    def status_check(connection = nil, &block)
      if block.nil?
        if @status_check
          @status_check.call(connection)
        else
          connection && !connection.closed?
        end
      else
        @status_check = block
      end
    end    
    
    def connected?
      @connected
    end
    
    def connect
      if !connected?
        @min_connections.times { add_connection! }
        grim_reaper
      end
    end
    
    def available_count
      @available.size
    end
    
    def connections_count
      @connections.size
    end
    
    def disconnect
      @mutex.synchronize do
        return if @disconnecting
        @disconnecting = true
        @connected = false # we don't want anyone thinking they can use this connection
        @grim_reaper.kill if @grim_reaper && @grim_reaper.alive?
        
        @available.dup.each do |conn|
          destroy_connection(conn)
        end
        
        while @connections.size > 0 && @queue.wait
          @available.dup.each do |conn|
            destroy_connection(conn)
          end
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
    
    def grim_reaper
      @grim_reaper.kill if @grim_reaper && @grim_reaper.alive?
      @grim_reaper = Thread.new do
        usage_history = []
        loop do
          if connected?
            @mutex.synchronize do
              dead = []

              @connections.each do |conn|
                dead << conn if !status_check(conn)
              end

              dead.each { |c| destroy_connection(c) }
              
              # restore to minimum number of connections if it's too low
              [@min_connections - @connections.size, 0].max.times do
                add_connection!
              end

              usage_history.push(@available.size)
              if usage_history.size >= 10
                # kill the minimum number of available connections over the last 10 checks
                # or the total connections minux the min connections, whichever is lower.
                # this ensures that you never go below min connections
                to_kill = [usage_history.min, @connections.size - @min_connections].min
                [to_kill, 0].max.times do
                  destroy_connection(@connections.last)
                end
                usage_history = []
              end

            end # end mutex
            sleep 30
          else
            break
          end # end if connected
        end
      end
    end
    
  end
end