module Pandemic::ServerSide
  module EventMachine
    module ConnectionShell
      def self.default_delegate
        @default_delegate
      end
      
      def self.default_delegate=(delegate)
        @default_delegate = delegate
      end
      
      def post_init
        @delegate = ConnectionShell.default_delegate
        @closed = false
      end
      
      def delegate=(delegate)
        @delegate = delegate
      end
      
      def unbind
        @closed = true
      end
      
      def hand_off_to(mod, &block)
        extend mod
        block.call(self) if block_given?
        receive_data(@buffer) if @buffer
      end
      
      def receive_data(data)
        (@buffer ||= "") << data
        
        if @buffer =~ /\n/
          data, @buffer = @buffer.split("\n", 2)
          @delegate.handle_data(data, self)
        end
      end
      
      def write(data)
        send_data(data)
      end
      
      def closed?
        @closed
      end
      
      def close
        close_connection true
      end
    end
  end
end