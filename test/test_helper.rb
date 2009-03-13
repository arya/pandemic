TEST_DIR = File.dirname(__FILE__)
%w(lib test).each do |dir|
  $LOAD_PATH.unshift "#{TEST_DIR}/../#{dir}"
end

require 'test/unit'
require 'pandemic'
require 'rubygems'
require 'shoulda'
require 'mocha'


blackhole = StringIO.new
$pandemic_logger = Logger.new(blackhole)

module TestHelper
  def wait_for_threads
    Thread.list.each do |thread|
      next if thread == Thread.current
      thread.join
    end
  end
end