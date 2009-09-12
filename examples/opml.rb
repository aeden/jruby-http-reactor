#!/usr/bin/env ruby
#
# Usage: jruby examples/opml.rb opml.xml
#
# Dependencies:
#
# hpricot (0.6.164)
# threadify (1.1.0)

require 'uri'
require 'rubygems'
require 'hpricot'
require 'threadify'
require File.dirname(__FILE__) + '/../lib/http_reactor'

def uris
  @uris ||= begin
    xml = File.read(ARGV.pop)
    doc = Hpricot::XML(xml)
    urls = (doc/'outline').map { |outline| outline['xmlUrl'] }
    urls.map { |url_string| URI.parse(url_string) }
  end
end

#uris.threadify(:each_slice, 1) do |slice|
  HttpReactor::Client.new(uris) do |response, context|
    puts "Response: #{response.status_line.status_code}"
  end
#end
puts "Processed #{uris.length} feeds"