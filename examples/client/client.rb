require 'rubygems'
require 'pandemic'
require 'json'
require 'pp'

class WordCounter
  include Pandemize
  
  def count(str)
    JSON.parse(pandemic.request(str))
  end
end


wc = WordCounter.new
counts = wc.count(File.read("constitution.txt"))
pp counts.to_a.sort{|lhs, rhs| lhs[1] <=> rhs[1]}.reverse[0, 10]