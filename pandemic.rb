require 'socket'
require 'thread'
require 'yaml'
require 'digest/md5'

require 'lib/base'
require 'lib/client'
require 'lib/server'
require 'lib/peer'
require 'lib/request'
require 'lib/config'
require 'lib/handler'

Pandemic::Config.load
server = Pandemic::Server.new(Pandemic::Handler)
server.start

# TODO:
# - seperate as gem that is included then start using method call
# - client side code
# - two executables to create server and client
# - graceful shutdown