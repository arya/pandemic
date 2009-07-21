module Pandemic
  module ServerSide
    class Config
      class << self
        attr_accessor :bind_to, :servers, :response_timeout, :fork_for_processor, :pid_file
        def load
          parse_args!
          raise "Interface to bind to is nil." unless @bind_to
        end
        
        def get(*args)
          args.size == 1 ?  @options[args.first] : @options.values_at(*args) if @options
        end
        
        private
        
        def parse_args!
          config_path = "pandemic_server.yml"
          index = nil
          attach = nil
          
          @bind_to = nil
          @pid_file = nil
          OptionParser.new do |opts|
            opts.on("-c", "--config [CONFIG-PATH]", "Specify the path to the config file") do |path|
              config_path = path
            end
            
            opts.on("-i", "--index [SERVER-INDEX]", "Specify the index of the server to attach to from the YAML file") do |i|
              index = i
            end

            opts.on("-a", "--attach [SERVER:PORT]", "Specify the host and port to attach to") do |a|
              attach = a
            end
            
            opts.on("-P", "--pid-file [PATH]", "Specify the path to write the PID to") do |path|
              @pid_file = path
            end
          end.parse!
          
          read_config_file(config_path)
          
          if index
            index = index.to_i if @server_map.is_a?(Array)
            server = @server_map[index]
            
            @bind_to = if server.is_a?(Hash)
              @options = server.values.first # there should only be one
              @server_map[index].keys.first
            else
              server
            end
          elsif attach
            @bind_to = attach
          end
          
        end
        
        def read_config_file(path)
          yaml = YAML.load_file(path)

          @server_map = yaml['servers'] || []
          @servers = @server_map.is_a?(Hash) ? @server_map.values : @server_map 
          @servers = @servers.collect { |s| s.is_a?(Hash) ? s.keys.first : s }

          @response_timeout = (yaml['response_timeout'] || 1).to_f

          @fork_for_processor = yaml['fork_for_processor']
        end
      end
    end
  end
end