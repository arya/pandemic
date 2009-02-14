require 'digest/md5'
module DM
  class Request
    @@request_count = 0
    attr_reader :body
    attr_accessor :max_responses
    def initialize(body)
      @@request_count += 1 # TODO: circle back to avoid big ints
      @body = body
      @responses = []
      @responses_mutex = Mutex.new
      @complete = false
    end
    
    def add_response(response)
      @responses_mutex.synchronize do
        @responses << response
        if @max_responses && @responses.size >= @max_responses
          @waiting_thread.wakeup if @waiting_thread
          @complete = true
        end
      end
    end
    
    def responses
      response = nil
      @responses_mutex.synchronize do
        response = @responses.clone # don't want to add things mid-way
      end
      response
    end
    
    def wait_for_responses
      return if @complete
      @waiting_thread = Thread.current
      sleep 1 # TODO: Constantize
      @waiting_thread = nil
    end

    def hash
      @hash ||= Digest::MD5.hexdigest("#{@@request_count} #{@body}")[0,10]
    end
  end
end