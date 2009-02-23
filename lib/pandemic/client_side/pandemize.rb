module Pandemic
  module ClientSide
    module Pandemize
      def self.included(klass)
        klass.class_eval do
          @@pandemize_connection ||= Pandemic::ClientSide::ClusterConnection.new
        end
      end
      def pandemic
        @@pandemize_connection
      end
    end
  end
end