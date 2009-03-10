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

Each value for the server list is the _host:port_ that a node can bind to. The servers value can be a hash or an array of hashes, but I'll get to that later. The response timeout is how long to wait for responses from nodes before returning to the client.

    # pandemic_client.yml
    servers:
      - host1:4000
      - host2:4000
    max_connections_per_server: 10
    min_connections_per_server: 1
The min/max connections refers to how many connections to each node. If you're using Rails, then just use 1 for both min/max since it's single threaded.

**More Config**
There are three ways to start a server:

  * ruby server.rb -i 0
  * ruby server.rb -i machine1hostname
  * ruby server.rb -a localhost:4000
  
The first refers to the index in the servers array:

    servers:
      - host1:4000 # started with ruby server.rb -i 0
      - host2:4000 # started with ruby server.rb -i 0
      
The second refers to the index in the servers _hash_. This can be particularly useful if you use the hostname as the key.

    servers:
      machine1: host1:4000 # started with ruby server.rb -i machine1
      machine2: host2:4000 # started with ruby server.rb -i machine2
      
The third is to specify the host and port explicitly. Ensure that the host and port you specify is actually in the config otherwise the other nodes won't be able to communicate with it.

You can also set node-specific configuration options.

      servers:
        - host1:4000:
            database: pandemic_node_1
            host: localhost
            username: foobar
            password: f00bar
        - host2:4000:
            database: pandemic_node_2
            host: localhost
            username: fizzbuzz
            password: f1zzbuzz
            
And you can access these additional options using _config.get(keys)_ in your handler:

    class Handler < Pandemic::ServerSide::Handler
      def initialize
        @dbh = Mysql.real_connect(*config.get('host', 'username', 'password', 'database')) 
      end
    end