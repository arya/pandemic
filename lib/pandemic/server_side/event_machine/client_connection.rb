module Pandemic::ServerSide
  module EventMachine
    module ClientConnection            
      EMPTY_STRING = ""
      REQUEST_FLAGS = Client::REQUEST_FLAGS
      REQUEST_REGEXP = /^([0-9]+)(?: ([#{REQUEST_FLAGS.values.join('')}]*))?$/
    
      def handler=(handler)
        @handler = handler
      end
      
      def unbind
        @handler.cleanup
      end
      
      def name
        @name ||= Socket.unpack_sockaddr_in(self.get_peername).reverse.join(":")
      end
      
      def unbind
        
      end
      
      def receive_data(data)
        (@buffer ||= "") << data

        while @buffer && ((!@size && @buffer =~ /\n/) || (@size && @buffer.size > @size))
          if !@size
            if @buffer =~ /\n/
              header, @buffer = @buffer.split("\n", 2)
              if header.strip =~ REQUEST_REGEXP
                @size, @flags = $1.to_i, $2.to_s.split(EMPTY_STRING)
              end
            end
          end

          if @size && @buffer.size >= @size
            @buffer, data = if @buffer.size > @size
              [@buffer[@size..-1], @buffer[0, @size]]
            else
              [nil, @buffer]
            end
            @handler.incoming_request(data, @flags, self)
            @size = nil
          end
        end
      end
    end
  end
end