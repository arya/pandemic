module Pandemic
  module Util
    def host_port(str)
      [str[/^[^:]+/], str[/[0-9]+$/].to_i]
    end
    
    def logger
      $pandemic_logger
    end
    
    def with_mutex(obj)
      obj.extend(MonitorMixin)
    end
  end
end