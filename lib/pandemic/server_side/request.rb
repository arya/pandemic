module Pandemic
  module ServerSide
    class Request
      class RequestCounter
        @@max = (2 ** 30) - 1
        def initialize
          @mutex = Mutex.new
          @counter = 0
        end
      
        def inc
          @mutex.synchronize do
            @counter += 1
            @counter = 0 if @counter >= @@max # to avoid Bignum, it's about 4x slower
            return @counter
          end
        end
      
        def to_s
          @mutex.synchronize do
            return @counter.to_s
          end
        end
      end
    
    
      @@request_count = RequestCounter.new
      attr_reader :body
      attr_accessor :max_responses
      
      def initialize(body)
        @@request_count.inc
        @body = body
        @responses = []
        @responses_mutex = Mutex.new
        @complete = false
      end
    
      def add_response(response)
        @responses_mutex.synchronize do
          return if @responses.frozen? # too late
          @responses << response
          if @max_responses && @responses.size >= @max_responses
            @waiting_thread.wakeup if @waiting_thread && @waiting_thread.status == "sleep"
            @complete = true
          end
        end
      end
    
      def responses
        @responses # its frozen so we don't have to worry about mutex
      end
    
      def wait_for_responses
        return if @complete
        @waiting_thread = Thread.current
        sleep Config.response_timeout
        # there is a race case where if the sleep finishes, 
        # and response comes in and has the mutex, and then array is frozen
        # it would be ideal to use monitor wait/signal here but the monitor implementation is currently flawed
        @responses_mutex.synchronize { @responses.freeze }
        @waiting_thread = nil
      end

      def hash
        @hash ||= Digest::MD5.hexdigest("#{@@request_count} #{@body}")[0,10]
      end
    end
  end
end