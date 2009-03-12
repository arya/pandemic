TEST_DIR = File.dirname(__FILE__)
%w(lib test).each do |dir|
  $LOAD_PATH.unshift "#{TEST_DIR}/../#{dir}"
end

require 'test/unit'
require 'pandemic'
require 'rubygems'
require 'shoulda'