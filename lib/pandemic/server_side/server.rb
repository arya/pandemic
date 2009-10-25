module Pandemic
  module ServerSide
    class Server
      include Util
      class StopServer < Exception; end
      class << self
        def boot(bind_to = nil)
          Config.load
          # Process.setrlimit(Process::RLIMIT_NOFILE, 4096) # arbitrary high number of max file descriptors.
          server = self.new(bind_to || Config.bind_to)
          set_signal_traps(server)
          server
        end
      
        private
        def set_signal_traps(server)
          interrupt_tries = 0
          Signal.trap(Signal.list["INT"]) do
            interrupt_tries += 1
            if interrupt_tries == 1
              server.stop
            else
              exit
            end
          end
        end
      end
      attr_reader :host, :port, :running
      def initialize(bind_to)
        write_pid_file
        
        @host, @port = host_port(bind_to)
        @clients = []
        @total_clients = 0
        @clients_mutex = Mutex.new
        @num_jobs_processed = MutexCounter.new
        @num_jobs_entered = MutexCounter.new
        @requests_per_second = RequestsPerSecond.new(10)
        
        @peers = with_mutex({})
        @servers = Config.servers
        @servers.each do |peer|
          next if peer == bind_to # not a peer, it's itself
          @peers[peer] = Peer.new(peer, self)
        end
      end
      
      def handler=(handler)
        @handler = handler
        @handler_instance = handler.new
      end
    
      def start
        raise "You must specify a handler" unless @handler
                
        # debug("Connecting to peers")

        EM.run do
          begin
            @running = true
            @running_since = Time.now
          
            EventMachine::ConnectionShell.default_delegate = self
            EM.start_server @host, @port, EventMachine::ConnectionShell
            
            @peers.values.each { |peer| peer.connect }
            # while @running
            #   begin
            #     # debug("Listening")
            #     conn = @listener.accept
            #     Thread.new(conn) { |c| handle_connection(c) }
            #   rescue Errno::ECONNABORTED, Errno::EINTR # TODO: what else can wrong here? this should be more robust.
            #     debug("Connection accepted aborted")
            #     conn.close if conn && !conn.closed?
            #   end
            # end
          rescue StopServer
            info("Stopping server")
            remove_pid_file
            @listener.close if @listener
            @peers.values.each { |p| p.disconnect }
            @clients.each {|c| c.close }
            self.processor.disconnect if Config.fork_for_processor
          rescue Exception => e
            warn("Unhandled exception in server listening thread:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
          end
        end
      end

      def stop
        # TODO: impl for EM
        @running = false
        @listener_thread.raise(StopServer)
      end
    
      def handle_data(identification, connection)
        begin
          identification = identification.strip
          # info("Incoming connection from #{connection.peeraddr.values_at(3,1).join(":")} (#{identification})")
          if identification =~ /^SERVER ([a-zA-Z0-9.]+:[0-9]+)$/
            # debug("Recognized as peer")
            host, port = host_port($1)
            matching_peer = @peers.values.detect { |peer| [peer.host, peer.port] == [host, port] }
            if matching_peer
              # debug("Found matching peer")
            else
              # debug("Didn't find matching peer, adding it")
              matching_peer = @peers.synchronize do
                hostport = "#{host}:#{port}"
                @servers.push(hostport) unless @servers.include?(hostport)
                @peers[hostport] ||= Peer.new(hostport, self)
              end
            end
            matching_peer.add_incoming_connection(connection)
          elsif identification =~ /^CLIENT$/
            # debug("Recognized as client")
            @clients_mutex.synchronize do
              @clients << Client.new(connection, self)
              @total_clients += 1
            end
          elsif identification =~ /^stats$/
            # debug("Stats request received")
            print_stats(connection)
          else
            debug("Unrecognized connection. Closing.")
            connection.close_connection # i dunno you
          end
        rescue Exception => e
          warn("Unhandled exception in handle connection method:\n#{e.inspect}\n#{e.backtrace.join("\n")}")
        end
      end
    
      def handle_client_request(request, client)
        # info("Handling client request")
        map = @handler_instance.partition(request, connection_statuses)
        # puts "#{request.hash} Server received"
        request.max_responses = map.size
        # debug("Sending client request to #{map.size} handlers (#{request.hash})")
        
        # debug("Waiting for responses")
        request.wait_for_responses do
          # debug("Done waiting for responses, calling reduce")
          # puts "#{request.hash} writing to client"
          client.response(@handler_instance.reduce(request))
        end
        
        # puts "#{request.hash} sending to peers"
        map.each do |peer, body|
          if @peers[peer]
            @peers[peer].client_request(request, body)
          end
        end
        
        if map[signature]
          # debug("Processing #{request.hash}")
          Thread.new do
            begin
              request.add_response(self.process(map[signature]))
            rescue Exception => e
              warn("Unhandled exception in local processing:\n#{e.inspect}#{e.backtrace.join("\n")}}")
            end
          end
        end
        
        @requests_per_second.hit
      end
    
      def process(body)
        @num_jobs_entered.inc
        response = if Config.fork_for_processor
          self.processor.with_connection {|con| con.process(body) } 
        else
          @handler_instance.process(body)
        end
        @num_jobs_processed.inc
        response
      end
    
      def signature
        @signature ||= "#{@host}:#{@port}"
      end
            
      def connection_statuses
        @servers.inject({}) do |statuses, server|
          if server == signature
            statuses[server] = :self
          else
            statuses[server] = @peers[server].connected? ? :connected : :disconnected
          end
          statuses
        end
      end
      
      def client_closed(client)
        @clients_mutex.synchronize do
          @clients.delete(client)
        end
      end
      
      def processor
        @processor ||= begin
          processor = ConnectionPool.new
          processor.create_connection { Processor.new(@handler) }
          processor
        end
      end
      
      private
      def print_stats(connection)
        EventMachine::StatsConnection.new(connection) do
          stats = collect_stats
          str = []
          str << "Uptime: #{stats[:uptime]}"
          str << "Number of Threads: #{stats[:num_threads]}"
          str << "Connected Clients: #{stats[:connected_clients]}"
          str << "Clients Ever: #{stats[:total_clients]}"
          str << "Connected Peers: #{stats[:connected_peers]}"
          str << "Disconnected Peers: #{stats[:disconnected_peers]}"
          str << "Total Requests: #{stats[:num_requests]}"
          str << "Pending Requests: #{stats[:pending_requests]}"
          str << "Late Responses: #{stats[:late_responses]}"
          str << "Total Jobs Processed: #{stats[:total_jobs_processed]}"
          str << "Pending Jobs: #{stats[:jobs_pending]}"
          str << "Requests per Second (10 sec): #{"%.1f" % stats[:rps_10]}"
          str << "Requests per Second (lifetime): #{"%.1f" % stats[:rps_lifetime]}"
          str << "Event Machine Connection Count: #{stats[:connection_count]}"
          str.join("\n")
        end
      end
      
      def debug(msg)
        logger.debug("Server #{signature}") {msg}
      end
      
      def info(msg)
        logger.info("Server #{signature}") {msg}
      end
      
      def warn(msg)
        logger.warn("Server #{signature}") {msg}
      end
      
      def collect_stats
        results = {}
        results[:num_threads] = Thread.list.size
        results[:connected_clients], results[:total_clients] = \
            @clients_mutex.synchronize { [@clients.size, @total_clients] }
            
        results[:connected_peers], results[:disconnected_peers] = \
            connection_statuses.inject([0,0]) do |counts, (server,status)|              
              if status == :connected
                counts[0] += 1
              elsif status == :disconnected
                counts[1] += 1
              end
              counts
            end
        results[:total_jobs_processed] = @num_jobs_processed.to_i
        results[:jobs_pending] = @num_jobs_entered.to_i - results[:total_jobs_processed]
        results[:num_requests] = Request.total_request_count
        results[:late_responses] = Request.total_late_responses
        results[:pending_requests] = @clients_mutex.synchronize do
          @clients.inject(0) do |pending, client|
            pending + (client.received_requests - client.responded_requests.to_i)
          end
        end
        results[:rps_10] = @requests_per_second.rps
        
        results[:uptime] = Time.now - @running_since
        results[:rps_lifetime] = results[:num_requests] / results[:uptime]
        results[:connection_count] = EM.connection_count
        
        results
      end
      
      def remove_pid_file
        File.unlink(Config.pid_file) if Config.pid_file && File.exists?(Config.pid_file)
      end

      def write_pid_file
        return if Config.pid_file.nil?
        File.open(Config.pid_file,"w") do |f|
          f.write(Process.pid)
          File.chmod(0644, Config.pid_file)
        end      
      end
      
    end
  end
end