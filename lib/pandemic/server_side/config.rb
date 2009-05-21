module Pandemic
  module ServerSide
    class Config
      attr_accessor :bind_to, :servers, :response_timeout
      
      def initialize(config_path, bind_to = nil)
        yaml = YAML.load_file(config_path)
      
        @server_map = yaml['servers'] || []
        @servers = @server_map.is_a?(Hash) ? @server_map.values : @server_map 
        @servers = @servers.collect { |s| s.is_a?(Hash) ? s.keys.first : s }
      
        @response_timeout = (yaml['response_timeout'] || 1).to_f
        @bind_to = bind_to.nil? ? extract_bind_to : bind_to
        raise "Interface to bind to is nil." unless @bind_to
      end

      def get(*args)
        args.size == 1 ?  @options[args.first] : @options.values_at(*args) if @options
      end

      private
      
      def extract_bind_to
        index = ARGV.index('-i')
        index2 = ARGV.index('-a')

        if index && (key = ARGV[index + 1])
          key = key.to_i if @server_map.is_a?(Array)
          server = @server_map[key]
          if server.is_a?(Hash)
            @options = server.values.first # there should only be one
            @server_map[key].keys.first
          else
            server
          end
        elsif index2 && (host = ARGV[index2 + 1])
          host
        else
          raise "You must specify which interface to bind to."
        end
      end
            
      class << self
        def load
          @config = new(extract_config_path)
        end
        
        def get(*args)
          @config.get(args)
        end
        
        def response_timeout
          @config.response_timeout
        end
        
        def bind_to
          @config.bind_to
        end
        
        def servers
          @config.servers
        end
        
        def extract_config_path
          index = ARGV.index('-c')
          if index && (path = ARGV[index + 1])
            path
          else
            "pandemic_server.yml"
          end
        end
      end
    end
  end
end