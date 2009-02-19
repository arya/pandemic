# Process.setrlimit(Process::RLIMIT_NOFILE, 1024)
require 'socket'
require 'thread'

require 'lib/base'
require 'lib/client'
require 'lib/server'
require 'lib/peer'
require 'lib/request'
require 'lib/handler'


SERVERS = %w{localhost:4000 localhost:4001 localhost:4002 localhost:4003}

Pandemic::Server.new(SERVERS[ARGV.first.to_i], SERVERS, Pandemic::Handler).start