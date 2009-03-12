require 'test_helper'

class UtilTest < Test::Unit::TestCase
  context "with the module methods" do
    setup do
      @util = Object.new
      @util.extend(Pandemic::Util)
    end
    
    should "parse out host and port" do
      assert_equal ["localhost", 4000], @util.host_port("localhost:4000")
    end
    
    should "include the monitor mixin" do
      object = Object.new
      assert !object.respond_to?(:synchronize)
      @util.with_mutex(object)
      assert object.respond_to?(:synchronize)
    end
  end
end