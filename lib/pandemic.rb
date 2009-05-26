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
require 'pandemic/server_side/processor'

require 'pandemic/client_side/config'
require 'pandemic/client_side/cluster_connection'
require 'pandemic/client_side/connection'
require 'pandemic/client_side/connection_proxy'
require 'pandemic/client_side/pandemize'

# TODO:
# - tests
# - IO timeouts/robustness
# - documentation
# - PING/PONG?

TCP_NO_DELAY_AVAILABLE =
    RUBY_VERSION < '1.9' ? Socket.constants.include?('TCP_NODELAY') : Socket.constants.include?(:TCP_NODELAY)

def epidemic!(bind_to = nil)
  if $pandemic_logger.nil?
    $pandemic_logger = Logger.new("pandemic.log")
    $pandemic_logger.level = Logger::INFO
    $pandemic_logger.datetime_format = "%Y-%m-%d %H:%M:%S "
  end
  Pandemic::ServerSide::Server.boot(bind_to)
end

::Pandemize = Pandemic::ClientSide::Pandemize