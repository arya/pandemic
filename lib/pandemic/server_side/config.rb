module Pandemic
  module ServerSide
    class Config
      class << self
        attr_accessor :bind_to, :servers, :response_timeout
        def load
          path = extract_config_path
          yaml = YAML.load_file(path)
        
          @server_map = yaml['servers'] || []
          @servers = @server_map.is_a?(Hash) ? @server_map.values : @server_map 
        
          @response_timeout = (yaml['response_timeout'] || 1).to_f
          @bind_to = extract_bind_to
        end
        
        private
        def extract_bind_to
          index = ARGV.index('-i')
          index2 = ARGV.index('-a')

          if index && (key = ARGV[index + 1])
            key = key.to_i if @server_map.is_a?(Array)
            @server_map[key]
          elsif index2 && (host = ARGV[index2 + 1])
            host
          else
            raise "You must specify which interface to bind to."
          end
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