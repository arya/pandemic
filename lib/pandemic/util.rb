module Pandemic
  module Util
    # TODO: add logging support
    def host_port(str)
      [str[/^[^:]+/], str[/[0-9]+$/].to_i]
    end
    
    def logger
      $logger
    end
  end
end