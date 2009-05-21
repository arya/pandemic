module Pandemic
  module ServerSide
    class Handler
      def config
        Config
      end
        
      def map(request, servers)
        map = {}
        servers.each do |server, status|
          if status != :disconnected
            map[server] = request.body
          end
        end
        map
      end

      def reduce(request)
        request.responses.join("")
      end

      def process(body)
        body
      end
      
      def filter_alive(servers)
        servers.keys.select{|k| servers[k] != :disconnected}
      end        
    end
  end
end