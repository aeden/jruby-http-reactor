#!/usr/bin/env jruby -Ilib -Ivendor
#
# Usage: jruby -Ilib -Ivendor examples/textfile.rb urls.txt
# Alt usage: examples/textfile urls.txt

require 'uri'
require 'http_reactor'

def requests
  @requests ||= begin
    puts "Generating requests"
    requests = []
    open(ARGV.pop) do |f|
      f.each do |line|
          requests << HttpReactor::Request.new(URI.parse(line)) if line =~ /^http:/
      end
    end
    puts "Generated #{requests.length} requests"
    requests
  end
end


HttpReactor::Client.new(requests) do |response, context|
  request = context.get_attribute('http_target_request')
  puts "Request URI: #{request.uri}"
  puts "Response: #{response.status_line.status_code}"
  puts "Content length: #{response.body.length}"
end
  
puts "Processed #{requests.length} feeds"