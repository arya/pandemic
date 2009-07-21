require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('pandemic', '0.4.4') do |p|
  p.description    = "A framework for distributing work for real-time services and offline tasks."
  p.url            = "https://github.com/arya/pandemic/"
  p.author         = "Arya Asemanfar"
  p.email          = "aryaasemanfar@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*", 'test/*']
  p.development_dependencies = ["shoulda", "mocha"]
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
