Process.setrlimit(Process::RLIMIT_NOFILE, 4096) # arbitrary high number of max file descriptors.
require 'socket'
require 'thread'
require 'digest/md5'

require 'lib/base'
require 'lib/client'
require 'lib/server'
require 'lib/peer'
require 'lib/request'     


SERVERS = %w{localhost:4000 localhost:4001 localhost:4002 localhost:4003}

Pandemic::Server.new(SERVERS[ARGV.first.to_i], SERVERS, Pandemic::Handler).start

# TODO:
# - Configuration handling (read yaml file, etc)
# - seperate as gem that is included then start using method call
# - client side code
# - two executables to create server and client