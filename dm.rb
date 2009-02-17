# Process.setrlimit(Process::RLIMIT_NOFILE, 1024)
require 'socket'
require 'thread'

require 'lib/base'
require 'lib/client'
require 'lib/server'
require 'lib/peer'
require 'lib/request'
require 'lib/handler'


DM_SERVERS = %w{localhost:4000 localhost:4001 localhost:4002 localhost:4003}

DM::Server.new(DM_SERVERS[ARGV.first.to_i], DM_SERVERS, DM::Handler).start