require 'rubygems'
require 'socket'
require 'fastthread' if RUBY_VERSION < '1.9'
require 'thread'
require 'monitor'
require 'yaml'
require 'digest/md5'
require 'logger'

require 'pandemic/util'
require 'pandemic/connection_pool'

require 'pandemic/server_side/config'
require 'pandemic/server_side/client'
require 'pandemic/server_side/server'
require 'pandemic/server_side/peer'
require 'pandemic/server_side/request'
require 'pandemic/server_side/handler'

require 'pandemic/client_side/config'
require 'pandemic/client_side/cluster_connection'
require 'pandemic/client_side/connection'
require 'pandemic/client_side/connection_proxy'
require 'pandemic/client_side/pandemize'

# TODO:
# - look into dropping connections
# - benchmark critical path
# - IO timeouts/robustness
# - work on protocol specs
# - PING/PONG?


def t(m, r = false)
  $start_time = Time.now.to_f if $start_time.nil? || r
  puts() if r
  puts "%.5f #{m}" % (Time.now.to_f - $start_time)
end

$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO
$logger.datetime_format = "%Y-%m-%d %H:%M:%S "

def epidemic!
  Pandemic::ServerSide::Server.boot
end

::Pandemize = Pandemic::ClientSide::Pandemize