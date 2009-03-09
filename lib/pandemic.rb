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
require 'pandemic/mutex_counter'

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
# - IO timeouts/robustness
# - implement stats tracking and stats client
# - documentation
# - PING/PONG?

$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG
$logger.datetime_format = "%Y-%m-%d %H:%M:%S "

def epidemic!
  Pandemic::ServerSide::Server.boot
end

::Pandemize = Pandemic::ClientSide::Pandemize