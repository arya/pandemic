module Pandemic
  module ServerSide
    class Processor
      def initialize(handler)
        @handler = handler
        read_from_parent, write_to_child = IO.pipe
        read_from_child, write_to_parent = IO.pipe
        
        @child_process_id = fork
        if @child_process_id
          # I'm the parent
          write_to_parent.close
          read_from_parent.close
          @out = write_to_child
          @in = read_from_child
        else
          # I'm the child
          write_to_child.close
          read_from_child.close
          @out = write_to_parent
          @in = read_from_parent
          wait_for_jobs
        end
      end
      
      def process(body)
        if parent?
          @out.puts(body.size.to_s)
          @out.write(body)
          ready, = IO.select([@in], nil, nil)
          if ready
            size = @in.gets.to_i
            result = @in.read(size)
            return result
          end
        else
          return @handler.process(body)
        end
      end
      
      def close(status = 0)
        if parent? && child_alive?
          @out.puts(status.to_s)
          @out.close
          @in.close
        else
          Process.exit!(status)
        end
      end
      
      def closed?
        !child_alive?
      end
      
      private
      def wait_for_jobs
        if child?
          while true
            ready, = IO.select([@in], nil, nil)
            if ready
              size = @in.gets.to_i
              if size > 0
                body = @in.read(size)
                result = process(body)
                @out.puts(result.size.to_s)
                @out.write(result)
              else
                self.close(size)
              end
            end
          end
        end
      end
      
      def parent?
        !!@child_process_id
      end
      
      def child?
        !parent?
      end
      
      def child_alive?
        parent? && !@in.closed?
        # TODO: do it.
        # parent? && # how to check status?
      end
    end
  end
end