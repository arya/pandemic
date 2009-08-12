require 'test_helper'

class PeerTest < Test::Unit::TestCase
  include TestHelper
  
  should "initialize a new connection pool" do
    connection_pool = mock()
    Pandemic::ConnectionPool.expects(:new).returns(connection_pool)
    connection_pool.expects(:create_connection)
    
    server = mock()
    peer = Pandemic::ServerSide::Peer.new("localhost:4000", server)
  end
  
  should "create a tcp socket" do
    connection_pool = mock()
    Pandemic::ConnectionPool.expects(:new).returns(connection_pool)
    connection_pool.expects(:create_connection).yields
    TCPSocket.expects(:new).with("localhost", 4000)
    
    server = mock()
    peer = Pandemic::ServerSide::Peer.new("localhost:4000", server)
  end
  
  context "with conn. pool" do
    setup do
      @connection_pool = mock()
      Pandemic::ConnectionPool.expects(:new).returns(@connection_pool)
      @connection_pool.expects(:create_connection)

      @server = mock()
      @peer = Pandemic::ServerSide::Peer.new("localhost:4000", @server)
    end
    
    should "send client request to peer connection" do
      request, body = stub(:hash => "asdasdfadsf"), "hello world"
      @connection_pool.stubs(:available_count => 1, :connections_count => 1)
      conn = mock()
      @connection_pool.expects(:with_connection).yields(conn)
      
      conn.stubs(:closed? => false)
      conn.expects(:write).with("PROCESS #{request.hash} #{body.size}\n#{body}")
      conn.expects(:flush)
      
      @peer.client_request(request, body)
    end
  end
end