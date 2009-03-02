module Pandemic
  module Util
    def host_port(str)
      [str[/^[^:]+/], str[/[0-9]+$/].to_i]
    end
    
    def logger
      $logger
    end
    
    def bm(title, &block)
      @times ||= Hash.new(0)
      begin
        start = Time.now.to_f
        yield block
      ensure
        @times[title] += (Time.now.to_f - start)
        $stdout.puts("#{title} #{@times[title]}")
      end
    end
  end
end