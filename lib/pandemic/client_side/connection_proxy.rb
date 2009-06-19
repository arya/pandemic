module Pandemic
  module ClientSide
    class ConnectionProxy
      instance_methods.each {|m| undef_method(m) if m !~ /^__/ && m !~ /object_id/ }
      
      def initialize(key, cluster)
        @key, @cluster = key, cluster
      end
      
      def request(body, options = {})
        @cluster.request(body, @key, options)
      end      
    end
  end
end