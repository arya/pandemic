module Pandemic::ServerSide
  module EventMachine
    module PeerConnection
      def handler=(handler)
        @handler = handler
      end
      
      def receive_data(data)
        (@buffer ||= "") << data
        
        
        while @buffer && ((!@size && @buffer.size >= 15) || (@size && @buffer.size >= @size))
          if !@size && @buffer.size >= 15
            @buffer, header = @buffer.size > 15 ? [@buffer[15..-1], @buffer[0,15]] : [nil, @buffer]
            if header =~ /^P/
              @type = :request
            else header =~ /^R/
              @type = :response
            end
            @hash, @size = header[1,10], header[11, 4].unpack('N').first
          end

          if @size && @buffer && @buffer.size >= @size
            @buffer, data = if @buffer.size > @size
              [@buffer[@size..-1], @buffer[0, @size]]
            else
              [nil, @buffer]
            end
            if @type == :request
              @handler.process_request(@hash, data, self)
            elsif @type == :response
              @handler.process_response(@hash, data)
            end
            @size = nil
          end
        end
      end
    end
  end
end