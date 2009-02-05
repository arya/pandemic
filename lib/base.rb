module DM
  class Base
    def initialize
      super
    end
    def host_port(str)
      [str[/^[^:]+/], str[/[0-9]+$/].to_i]
    end
  end
end