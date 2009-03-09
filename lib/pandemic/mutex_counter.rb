module Pandemic
  class MutexCounter
    MAX = (2 ** 30) - 1
    def initialize
      @mutex = Mutex.new
      @counter = 0
      @resets = 0
    end

    def real_total
      @mutex.synchronize { (@resets * MAX) + @counter }
    end

    def inc
      @mutex.synchronize do
        if @counter >= MAX
          @counter = 0  # to avoid Bignum, it's about 4x slower
          @resets += 1
        end
        @counter += 1
      end
    end
  end
end