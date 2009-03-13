require 'test_helper'

class ConnectionPoolTest < Test::Unit::TestCase
  include TestHelper
  context "without a create connection block" do
    setup do
      @connection_pool = Pandemic::ConnectionPool.new
    end
    
    should "raise an exception when trying to connect" do
      assert_raises Pandemic::ConnectionPool::CreateConnectionUndefinedException do
        @connection_pool.connect
      end
    end
  end
  
  context "with a connection pool" do
    setup do
      @connection_pool = Pandemic::ConnectionPool.new
      @connection_creator = mock()
    end
    
    should "call create connection after its defined" do
      @connection_creator.expects(:create).at_least(0)
      @connection_pool.create_connection do
        @connection_creator.create
      end
    end
    
  end
  
  context "with a max connections of 2" do
    setup do
      @connection_pool = Pandemic::ConnectionPool.new(:max_connections => 2, :timeout => 0.01)
      @connection_creator = mock()
    end
    
    should "raise timeout exception when no connections available" do
      @connection_creator.expects(:create).twice
      @connection_pool.create_connection do
        @connection_creator.create
        conn = mock()
        conn.expects(:closed?).returns(false).at_least(0)
        conn
      end
      
      assert_raises Pandemic::ConnectionPool::TimedOutWaitingForConnectionException do
        @connection_pool.with_connection do |conn1|
          @connection_pool.with_connection do |conn2|
            @connection_pool.with_connection do |conn3|
              fail("there should only be two connections")
            end
          end
        end
      end
    end
    
    should "should checkin a connection and allow someone check the same one out" do
      @connection_creator.expects(:create).twice
      @connection_pool.create_connection do
        @connection_creator.create
        conn = mock()
        conn.expects(:closed?).returns(false).at_least(0)
        conn
      end
      
      @connection_pool.with_connection do |conn1|
        conn2, conn3 = nil, nil
        
        @connection_pool.with_connection do |conn|
          conn2 = conn
        end
        @connection_pool.with_connection do |conn|
          conn3 = conn
        end
        
        assert_equal conn2, conn3
      end
    end
    
    should "should checkin connection even if there is an exception" do
      @connection_creator.expects(:create).once
      @connection_pool.create_connection do
        @connection_creator.create
        conn = mock()
        conn.expects(:closed?).returns(false).at_least(0)
        conn
      end
      before = @connection_pool.available_count
      begin
        @connection_pool.with_connection do |conn1|
          raise TestException
        end
      rescue TestException
      end
      after = @connection_pool.available_count
      
      assert_equal before, after
    end
  end
  
  context "with a min connections of 2" do
    setup do
      @connection_pool = Pandemic::ConnectionPool.new(:min_connections => 2)
      @connection_creator = mock()
    end
    
    should "call create connection twice" do
      @connection_creator.expects(:create).twice
      @connection_pool.create_connection do
        @connection_creator.create
      end
    end
    
  end
end
