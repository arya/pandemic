module Pandemic
  module ServerSide
    class Peer
      class PeerUnavailableException < StandardError; end
      include Util
      attr_reader :host, :port
      
      def initialize(addr, server)
        @host, @port = host_port(addr)
        @server = server
        @pending_requests = with_mutex({})
        @inc_threads_mutex = Mutex.new
      end
      
      def connect
        return if self.connected?
        @connection = EM.connect(@host, @port, EventMachine::ConnectionShell) do |conn|
          conn.hand_off_to(EventMachine::PeerConnection) do |c|
            c.handler = self
          end
          conn.write("SERVER #{@server.signature}\n")
        end
      end
      
      def disconnect
        @connection.close if self.connected?
      end
      
      def connected?
        @connection && !@connection.closed?
      end
    
      def client_request(request, body)
        # debug("Sending client's request to peer")
        # debug("Connection pool has #{@connection_pool.available_count} of #{@connection_pool.connections_count} connections available")

        successful = true
        @pending_requests.synchronize do
          @pending_requests[request.hash] = request
        end
        begin
          if self.connected?
            # debug("Writing client's request #{request.hash}")
            # puts "#{request.hash} asking peer"
            @connection.write("P#{request.hash}#{[body.size].pack('N')}#{body}")
            # debug("Finished writing client's request")
          else
            successful = false
          end
        rescue Exception
          @pending_requests.synchronize { @pending_requests.delete(request.hash) }
          raise
        else
          if !successful
            @pending_requests.synchronize { @pending_requests.delete(request.hash) }
          end
        end
      end
    
      def add_incoming_connection(conn)
        # debug("Adding incoming connection")

        # connect # if we're not connected, we should be
        @connection = conn
        
        conn.hand_off_to(EventMachine::PeerConnection)
        conn.handler = self
      end
    
      def process_request(hash, body, connection)
        EM.defer do
          # puts "#{hash} asked by peer"
          begin
            # debug("Starting processing thread (#{hash})")
            response = @server.process(body)
            EM.schedule do
              # puts "#{hash} Responding to peer"
              connection.write("R#{hash}#{[response.size].pack('N')}#{response}")
            end
            # debug( "Finished sending response (#{hash})")
          rescue Exception => e
            warn("Unhandled exception in process request thread:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          end
        end
      end
    
      def process_response(hash, body)
        # EM.defer do
        # # puts "#{hash} from peer"
          begin
            # debug("Finding original request (#{hash})")
            original_request = @pending_requests.synchronize { @pending_requests.delete(hash) }
            if original_request
              # debug("Found original request, adding response")
              original_request.add_response(body) 
            else
              warn("Original response not found (#{hash})")
            end
          rescue Exception => e
            warn("Unhandled exception in process response thread:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          end
        # end
      end
      
      def debug(msg)
        logger.debug("Peer #{@host}:#{@port}")  { msg }
      end
      
      def warn(msg)
        logger.warn("Peer #{@host}:#{@port}")  { msg }
      end
    end
  end
end