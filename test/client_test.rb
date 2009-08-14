require File.dirname(__FILE__) + '/test_helper'

class ClientTest < Test::Unit::TestCase
  def test_new
    assert_nothing_raised do
      uris = [
        'http://www.yahoo.com/', 
        'http://www.google.com/', 
        'http://www.apache.org/',
        'http://anthony.mp/about_me'
      ].map { |url_string| URI.parse(url_string) }
      HttpReactor::Client.new(uris)
    end
  end
end