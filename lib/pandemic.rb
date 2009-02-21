require 'socket'
require 'thread'
require 'yaml'
require 'digest/md5'

require 'pandemic/server_side/base'
require 'pandemic/server_side/client'
require 'pandemic/server_side/server'
require 'pandemic/server_side/peer'
require 'pandemic/server_side/request'
require 'pandemic/server_side/config'
require 'pandemic/server_side/handler'

# TODO:
# - work on protocol specs
# - client side code
# - two executables to create server and client
# - IO timeouts
# - PING/PONG