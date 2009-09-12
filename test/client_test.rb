require File.dirname(__FILE__) + '/test_helper'
require 'uri'

class ClientTest < Test::Unit::TestCase
  def uris
    @uris ||= [
      'http://www.yahoo.com/', 
      'http://www.google.com/', 
      'http://www.apache.org/',
      'http://anthony.mp/about_me'
    ].map { |url_string| URI.parse(url_string) }
  end
  
  def test_new
    assert_nothing_raised do
      HttpReactor::Client.new(uris)
    end
  end
  
  def test_proc
    handler = Proc.new { |response, context|
      puts "Response: #{response.status_line.status_code}"
    }
    HttpReactor::Client.new(uris, handler)
  end
  
  def test_block
    HttpReactor::Client.new(uris) do |response, context|
      puts "Response: #{response.status_line.status_code}"
    end
  end
  
end