module Pandemic
  module ServerSide
    class Base
      # TODO: add logging support
      def host_port(str)
        [str[/^[^:]+/], str[/[0-9]+$/].to_i]
      end
    end
  end
end