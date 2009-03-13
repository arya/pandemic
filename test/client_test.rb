require 'test_helper'

class ClientTest < Test::Unit::TestCase
  include TestHelper
  
  context "with a client object" do
    setup do
      @server = mock()
      @server.expects(:running).returns(true)
      @connection = mock()
      @connection.expects(:peeraddr).returns(['','','',''])
      @connection.expects(:nil?).returns(false).at_least_once
      @client = Pandemic::ServerSide::Client.new(@connection, @server)
    end
    
    should "read size from the connection" do
      @connection.expects(:gets).returns("5\n")
      @server.expects(:client_closed).with(@client)
      @client.listen
      wait_for_threads
    end
    
    should "read body from the connection" do
      @connection.expects(:gets).returns("5\n")
      @connection.expects(:read).with(5).returns("hello")
      @server.expects(:client_closed).with(@client)
      @client.listen    
      wait_for_threads
    end
    
    should "call handle request body on server" do
      @connection.expects(:gets).returns("5\n")
      @connection.expects(:read).with(5).returns("hello")
      
      request = mock()
      Pandemic::ServerSide::Request.expects(:new).returns(request)
      @server.expects(:handle_client_request).with(request)
      
      @server.expects(:client_closed).with(@client)
      @client.listen    
      wait_for_threads
    end
    
    should "write response back to client" do
      @connection.expects(:gets).returns("5\n")
      @connection.expects(:read).with(5).returns("hello")
      
      request = mock()
      response = "olleh"
      Pandemic::ServerSide::Request.expects(:new).returns(request)
      @server.expects(:handle_client_request).with(request).returns(response)
      
      @connection.expects(:write).with("5\n#{response}")
      @connection.expects(:flush)
      
      @server.expects(:client_closed).with(@client)
      @client.listen    
      wait_for_threads
    end
    
    should "close the connection on nil response" do
      @connection.expects(:gets).returns(nil)
      @connection.expects(:close)
      
      @server.expects(:client_closed).with(@client)
      @client.listen
      wait_for_threads
    end
    
    should "close the connection on disconnect" do
      @connection.expects(:gets).raises(Pandemic::ServerSide::Client::DisconnectClient)
      @connection.expects(:closed?).returns(false)
      @connection.expects(:close)
      
      @server.expects(:client_closed).with(@client)
      @client.listen
      wait_for_threads
    end
  end
end