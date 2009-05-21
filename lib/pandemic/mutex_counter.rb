module Pandemic
  class MutexCounter
    MAX = (2 ** 30) - 1
    def initialize(max = MAX)
      @mutex = Mutex.new
      @counter = 0
      @resets = 0
      @max = max
    end

    def real_total
      @mutex.synchronize { (@resets * @max) + @counter }
    end
    alias_method :to_i, :real_total
    
    def value
      @mutex.synchronize { @counter }
    end

    def inc
      @mutex.synchronize do
        if @counter >= @max
          @counter = 0  # to avoid Bignum, it's about 4x slower
          @resets += 1
        end
        @counter += 1
      end
    end
  end
end