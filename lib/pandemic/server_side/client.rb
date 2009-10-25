module Pandemic
  module ServerSide
    class Client
      REQUEST_FLAGS = {:async => 'a'}
      class DisconnectClient < Exception; end
      include Util

      attr_accessor :received_requests, :responded_requests
      attr_accessor :signature

      def initialize(connection, server)
        @server = server
        @received_requests = 0
        @responded_requests = MutexCounter.new                                                             
        @current_request = nil
        @responder = Mutex.new

        @signature = Socket.unpack_sockaddr_in(connection.get_peername).reverse.join(":")
        connection.hand_off_to(EventMachine::ClientConnection) do |c|
          c.handler = self
        end
      end

      def incoming_request(body, flags, connection)
        begin
          @received_requests += 1
          if flags.include?(REQUEST_FLAGS[:async])
            EM.defer do
              handle_request(body, connection)
              @responded_requests.inc
            end
          else
            handle_request(body, connection)
          end
        end
      end

      def cleanup
        @server.client_closed(self)
      end

      def handle_request(request, connection)
        begin
          @waiting_for_response = connection
          @server.handle_client_request(Request.new(request), self)
        rescue Exception => e
          warn("Unhandled exception in handle client request:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          nil
        end
      end
      
      def response(data)
        @responder.synchronize do
          if @waiting_for_response
            @waiting_for_response.write("#{data.size}\n#{data}")
            # @responded_requests.inc
            @waiting_for_response = nil
          end
        end
      end

      private
      def debug(msg)
        logger.debug("Client #{signature}") {msg}
      end

      def info(msg)
        logger.info("Client #{signature}") {msg}
      end

      def warn(msg)
        logger.warn("Client #{signature}") {msg}
      end
    end
  end
end