require 'test_helper'

class FunctionalTest < Test::Unit::TestCase
  include TestHelper
  should "work" do
    ignore_threads = Thread.list
    ARGV.replace(["-i", "0", "-c", "test/pandemic_server.yml"]) # :(
    Pandemic::ClientSide::Config.config_path = "test/pandemic_client.yml"
    
    server = epidemic!
    server.handler = Class.new(Pandemic::ServerSide::Handler) do
      def process(body)
        body.reverse
      end
    end
    server.start
    
    client = Class.new do
      include Pandemize
    end.new
    client.extend(Pandemize)
    assert_equal "dlrow olleh", client.pandemic.request("hello world")
    server.stop
    wait_for_threads(ignore_threads)
  end
  
  should "work with multiple peers" do
    ignore_threads = Thread.list
    handler = Class.new(Pandemic::ServerSide::Handler) do
      def process(body)
        body.reverse
      end
    end
    
    ARGV.replace(["-i", "0", "-c", "test/pandemic_server.yml"]) # :(    
    server = epidemic!
    server.handler = handler
    server.start
    
    ARGV.replace(["-i", "1", "-c", "test/pandemic_server.yml"]) # :(    
    server2 = epidemic!
    server2.handler = handler
    server2.start
    
    Pandemic::ClientSide::Config.config_path = "test/pandemic_client.yml"
    
    client = Class.new do
      include Pandemize
    end.new
    client.extend(Pandemize)
    assert_equal "raboofraboof", client.pandemic.request("foobar")
    server.stop
    server2.stop
    wait_for_threads(ignore_threads)
  end
end
