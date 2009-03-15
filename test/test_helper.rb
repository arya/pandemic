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
  class TestException < Exception; end
  def wait_for_threads(ignore = [Thread.current])
    Thread.list.each do |thread|
      next if ignore.include?(thread)
      thread.join
    end
  end
end