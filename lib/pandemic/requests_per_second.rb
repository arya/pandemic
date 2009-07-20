module Pandemic
  class RequestsPerSecond
    def initialize(sample_size = 10)
      @hits = Array.new(sample_size + 2)
      @last_hit_at = nil
    end

    def hit(now = Time.now.to_i)
      key = now % @hits.size
      if @hits[key].nil? || @hits[key][0] != now
        @hits[key] = [now, 0]
      end
      @hits[key][1] += 1
      @last_hit_at = now
    end

    def rps(now = Time.now.to_i)
      return 0 if @last_hit_at.nil?
      entries_to_go_back = @hits.size - (now - @last_hit_at) - 2
      return 0 if entries_to_go_back <= 0
      sum = 0
      entries_to_go_back.times do |i|
        now -= 1 
        if @hits[now % @hits.size] && @hits[now % @hits.size][0] == now
          sum += @hits[now % @hits.size][1] 
        end
      end
      return sum.to_f / (@hits.size - 2)
    end
  end
end