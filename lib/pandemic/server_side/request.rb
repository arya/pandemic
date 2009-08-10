module Pandemic
  module ServerSide
    class Request    
      include Util
      
      @@request_count = MutexCounter.new
      @@late_responses = MutexCounter.new
      attr_reader :body
      attr_accessor :max_responses
      attr_accessor :data
      
      def self.total_request_count
        @@request_count.real_total
      end
      
      def self.total_late_responses
        @@late_responses.real_total
      end
      
      def initialize(body)
        @request_number = @@request_count.inc
        @body = body
        @responses = []
        @responses_mutex = Monitor.new
        @waiter = @responses_mutex.new_cond
        @complete = false
      end
    
      def add_response(response)
        @responses_mutex.synchronize do
          if @responses.frozen? # too late
            @@late_responses.inc
            return  
          end
          # debug("Adding response")
          @responses << response
          if @max_responses && @responses.size >= @max_responses
            # debug("Hit max responses, waking up waiting thread")
            wakeup_waiting_thread
            @complete = true
          end
        end
      end
      
      def wakeup_waiting_thread
        @waiter.signal if @waiter
      end
    
      def responses
        @responses # its frozen so we don't have to worry about mutex
      end
      
      def cancel!
        # consider telling peers that they should stop, but for now this is fine.
        @responses_mutex.synchronize do
          wakeup_waiting_thread
        end
      end
    
      def wait_for_responses
        @responses_mutex.synchronize do
          return if @complete
          if Config.response_timeout <= 0
            @waiter.wait
          elsif !MONITOR_TIMEOUT_AVAILABLE
            Thread.new do
              sleep Config.response_timeout
              wakeup_waiting_thread
            end
            @waiter.wait
          else
            @waiter.wait(Config.response_timeout)
          end
          @responses.freeze
        end
      end
      
      def hash
        @hash ||= Digest::MD5.hexdigest("#{@request_number} #{@body}")[0,10]
      end
      
      private
      def debug(msg)
        logger.debug("Request #{hash}") {msg}
      end
      
      def info(msg)
        logger.info("Request #{hash}") {msg}
      end
    end
  end
end