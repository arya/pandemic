module Pandemic
  module ServerSide
    class Handler
      def config
        Config
      end
        
      def map(request, servers)
        raise "Implement"
      end

      def reduce(request)
        raise "Implement"
      end

      def process(body)
        raise "Implement"
      end
    end
  end
end