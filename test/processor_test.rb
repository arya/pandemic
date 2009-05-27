require 'test_helper'

class HandlerTest < Test::Unit::TestCase
  include TestHelper
  
  context "with a basic echo processor" do
    setup do
      echo = Class.new do
        def process(body)
          body.reverse
        end
      end

      @processor = Pandemic::ServerSide::Processor.new(echo)
    end
    
    should "have a running child process" do
      assert !@processor.closed?
    end
    
    should "close running child" do
      assert !@processor.closed?
      @processor.close
      assert @processor.closed?
    end
    
    should "echo back" do
      10.times do |i| # just to test the loop part
        assert_equal "#{i} dlrow olleh", @processor.process("hello world #{i}")
      end
    end
  end
end