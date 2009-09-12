#!/usr/bin/env ruby
#
# Usage: jruby examples/opml.rb opml.xml

require 'uri'
require 'rubygems'
require 'hpricot'
require 'threadify'
require File.dirname(__FILE__) + '/../lib/http_reactor'

def uris
  xml = File.read(ARGV.pop)
  doc = Hpricot::XML(xml)
  urls = (doc/'outline').map { |outline| outline['xmlUrl'] }
  urls.map { |url_string| URI.parse(url_string) }
end

uris.threadify(:each_slice, 2) do |slice|
  HttpReactor::Client.new(slice) do |response, context|
    puts "Response: #{response.status_line.status_code}"
  end
end