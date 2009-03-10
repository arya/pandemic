# Pandemic
Pandemic is a map-reduce framework. You give it the map, process, and reduce methods and it handles the rest. It works both in Ruby 1.8 and Ruby 1.9, and performs better on 1.9.

## Examples
**Server**  
    
    require 'rubygems'
    require 'pandemic'

    class Handler < Pandemic::ServerSide::Handler
      def process(body)
        body.reverse
      end
    end

    pandemic_server = epidemic!
    pandemic_server.handler = Handler.new
    pandemic_server.start.join

In this example, the handler doesn't define the map or reduce methods, and the defaults are used. The default for each is as follows:

  * map: Send the full request body to every connected node
  * process: Return the body (do nothing)
  * reduce: Concatenate all the responses

**Client**  

    require 'rubygems'
    require 'pandemic'

    class TextFlipper
      include Pandemize
      def flip(str)
        pandemic.request(str)
      end
    end


**Config**  
Both the server and client have config files:

    # pandemic_server.yml
    servers:
      - host1:4000
      - host2:4000
    response_timeout: 0.5

The servers value can be a hash or an array of hashes, but I'll get to that later.
The response timeout is how long to wait for responses from nodes before returning to the client.

    # pandemic_client.yml
    servers:
    - host1:4000
    - host2:4000
    max_connections_per_server: 10
    min_connections_per_server: 1
The min/max connections refers to how many connections to each node. If you're using Rails, then just use 1 for both min/max since it's single threaded.