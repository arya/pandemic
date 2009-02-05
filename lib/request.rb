module DM
  class Request
    attr_reader :body
    def initialize(body)
      @body = body
      @responses = []
      @responses_monitor = Monitor.new
    end
    
    def add_response(response)
      @responses_monitor.synchronize do
        @responses << response
      end
    end
  end
end