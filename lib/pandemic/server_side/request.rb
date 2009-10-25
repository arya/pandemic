require 'set'
module Pandemic
  module ServerSide
    class Request    
      include Util
      
      @@request_count = MutexCounter.new
      @@late_responses = MutexCounter.new
      
      @@in_queue = Set.new
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
        @@in_queue.add(self.hash) 
      end
      # EM.schedule { EM.add_periodic_timer(1) { puts @@in_queue.entries.inspect} } 
    
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
            @@in_queue.delete(self.hash)
            @complete = true
            wakeup_waiting_thread
          end
        end
      end
      
      def wakeup_waiting_thread
        EM.cancel_timer(@timer) if @timer
        @response_block.call
      end
    
      def responses
        @responses # its frozen so we don't have to worry about mutex
      end
      
      def wait_for_responses(&block)
        @response_block = block
        if Config.response_timeout > 0
          @timer = EM.add_timer(Config.response_timeout) do
            @responses.freeze
            block.call
          end
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