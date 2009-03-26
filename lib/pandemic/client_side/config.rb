module Pandemic
  module ClientSide
    class Config
      class << self
        @@load_mutex = Mutex.new
        attr_accessor :config_path, :loaded
        attr_accessor :servers, :max_connections_per_server, :min_connections_per_server,
                      :connection_wait_timeout, :response_timeout
        def load
          @@load_mutex.synchronize do
            return if self.loaded
            path = config_path
            yaml = YAML.load_file(path)

            @servers = yaml['servers'] || []
            # this is just so if we copy/paste from server's yml to client's yml, it will still work
            @servers = @servers.values if @servers.is_a?(Hash)
            @servers.sort! # so it's consistent across all clients

            @max_connections_per_server = (yaml['max_connections_per_server'] || 1).to_i
            @min_connections_per_server = (yaml['min_connections_per_server'] || 1).to_i
            @connection_wait_timeout = (yaml['connection_wait_timeout'] || 1).to_f
            @response_timeout = (yaml['response_timeout'] || 1).to_f
            self.loaded = true
          end
        end
      
        def config_path
          @config_path || "pandemic_client.yml"
        end
      end
    end
  end
end