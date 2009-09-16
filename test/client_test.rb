require File.dirname(__FILE__) + '/test_helper'
require 'uri'
require 'mime/types'

class ClientTest < Test::Unit::TestCase
  def requests
    @requests ||= [
      'http://www.yahoo.com/', 
      'http://www.google.com/', 
      'http://www.apache.org/',
      'http://anthony.mp/about_me'
    ].map { |url_string| HttpReactor::Request.new(URI.parse(url_string)) }
  end
  
  def test_new
    assert_nothing_raised do
      HttpReactor::Client.new(requests)
    end
  end
  
  def test_proc
    handler = Proc.new do |response, context|
      assert_equal 200, response.code
      assert response.body.length > 0
      mime_type = MIME::Types[response.content_type].first
      assert_equal "text/html", mime_type.content_type
    end
    HttpReactor::Client.new(requests, handler)
  end
  
  def test_block
    HttpReactor::Client.new(requests) do |response, context|
      assert_equal 200, response.status_line.status_code
      assert_equal 200, response.code
      mime_type = MIME::Types[response.content_type].first
      assert_equal "text/html", mime_type.content_type
      puts "request ur: #{context.getAttribute('http_target_request').uri}"
      puts "content-length: #{response.content_length}"
      assert response.body.length > 0
    end
  end
  
  def test_body
    HttpReactor::Client.new(requests) do |response, context|
      if response.code == 200
        puts response.body
      end
    end
  end
  
end