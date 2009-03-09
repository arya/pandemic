module Pandemic
  module ServerSide
    class Request    
      include Util
      
      @@request_count = MutexCounter.new
      @@late_responses = MutexCounter.new
      attr_reader :body
      attr_accessor :max_responses
      
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
        @responses_mutex = Mutex.new
        @complete = false
      end
    
      def add_response(response)
        @responses_mutex.synchronize do
          if @responses.frozen? # too late
            @@late_responses.inc
            return  
          end
          debug("Adding response")
          @responses << response
          if @max_responses && @responses.size >= @max_responses
            debug("Hit max responses, waking up waiting thread")
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