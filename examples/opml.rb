#!/usr/bin/env jruby -rubygems -Ilib -Ivendor
#
# Usage: jruby -rubygems -Ilib -Ivendor examples/opml.rb opml.xml
# Alt usage: ./examples/opml.rb opml.xml
#
# Dependencies:
#
# hpricot (0.6.164)

require 'uri'
require 'hpricot'
require 'http_reactor'

def requests
  @requests ||= begin
    xml = File.read(ARGV.pop)
    doc = Hpricot::XML(xml)
    urls = (doc/'outline').map { |outline| outline['xmlUrl'] }
    urls.map { |url_string| HttpReactor::Request.new(URI.parse(url_string)) }
  end
end

HttpReactor::Client.new(requests) do |response, context|
  puts "Response: #{response.status_line.status_code}"
  puts "Content length: #{response.body.length}"
end  
puts "Processed #{requests.length} feeds"