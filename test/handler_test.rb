require 'test_helper'

class HandlerTest < Test::Unit::TestCase
  include TestHelper
  
  context "with a request object" do
    setup do
      @request = mock()
      @servers = {
        1 => :self,
        2 => :disconnected,
        3 => :connected
      }
      @handler = Pandemic::ServerSide::Handler.new
    end
    
    should "concatenate all the results" do
      @request.expects(:responses).once.returns(%w{1 2 3})
      assert_equal "123", @handler.reduce(@request)
    end
    
    should "map to all non-disconnected nodes" do
      @request.expects(:body).twice.returns("123")
      map = @handler.map(@request, @servers)
      # see setup for @servers
      assert_equal 2, map.size
      assert_equal "123", map[1]
      assert_equal "123", map[3]
    end
  end
end