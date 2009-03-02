module Pandemic
  module ClientSide
    class ConnectionProxy
      instance_methods.each {|m| undef_method(m) if m !~ /^__/ && m !~ /object_id/ }
      
      def initialize(key, cluster)
        @key, @cluster = key, cluster
      end
      
      def request(body)
        @cluster.request(body, @key)
      end
    end
  end
end