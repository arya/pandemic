module Pandemic
  module ClientSide
    module Pandemize
      def self.included(klass)
        klass.class_eval do
          @pandemize_connection ||= Pandemic::ClientSide::ClusterConnection.new
          def self.pandemize_connection
            @pandemize_connection
          end
        end
      end
      def pandemic
        self.class.pandemize_connection
      end
    end
  end
end