require 'rubygems'
require 'pandemic'
require 'json'

class WordCounter < Pandemic::ServerSide::Handler
  def map(request, servers)
    # select only the alive servers (non-disconnected)
    only_alive = servers.keys.select{|k| servers[k] != :disconnected}
    
    mapping = {}
    intervals = (request.body.size / only_alive.size.to_f).floor
    
    pos = 0
    only_alive.size.times do |i|
      if i == only_alive.size - 1 # last peer gets the rest
        mapping[only_alive[i]] = request.body[pos..-1]
      else
        next_pos = request.body[(pos + intervals)..-1].index(/ /) + pos + intervals
        mapping[only_alive[i]] = request.body[pos...next_pos]
        pos = next_pos
      end
    end
    mapping
  end
  
  def process(text)
    counts = Hash.new(0)
    text.scan(/\w+/) do |word|
      counts[word.strip.downcase] += 1
    end
    counts.to_json
  end
  
  def reduce(request)
    total_counts = Hash.new(0)
    request.responses.each do |counts|
      JSON.parse(counts).each do |word, count|
        total_counts[word] += count
      end
    end
    total_counts.to_json
  end
end

server = epidemic!
server.handler = WordCounter
server.start.join