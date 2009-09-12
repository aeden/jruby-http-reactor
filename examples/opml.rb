#!/usr/bin/env ruby
#
# Usage: jruby examples/opml.rb opml.xml
#
# Dependencies:
#
# hpricot (0.6.164)
# threadify (1.1.0) (optional, uncomment in code)

require 'uri'
require 'rubygems'
require 'hpricot'
#require 'threadify'
require File.dirname(__FILE__) + '/../lib/http_reactor'

def requests
  @requests ||= begin
    xml = File.read(ARGV.pop)
    doc = Hpricot::XML(xml)
    urls = (doc/'outline').map { |outline| outline['xmlUrl'] }
    urls.map { |url_string| HttpReactor::Request.new(URI.parse(url_string)) }
  end
end

#uris.threadify(:each_slice, 1) do |slice|
  HttpReactor::Client.new(requests) do |response, context|
    puts "Response: #{response.status_line.status_code}"
  end
#end
puts "Processed #{requests.length} feeds"