module Pandemic
  module ServerSide
    class Handler
      class << self
        # example/dummy handler
        def map(request, servers)
          count = 0
          servers.reject{|server, status| status == :disconnected}.keys.inject({}) do |h, e|
            h[e] = "#{request.body}:#{count+=1}"
            h
          end
        end

        def reduce(request)
          request.responses.join(" | ")
        end

        def process(body)
          "#{body}!"
        end
      end
    end
  end
end