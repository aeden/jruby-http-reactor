require File.dirname(__FILE__) + '/test_helper'

class ClientTest < Test::Unit::TestCase
  def test_new
    assert_nothing_raised do
      hosts = ['www.yahoo.com', 'www.google.com', 'www.apache.org']
      HttpReactor::Client.new(hosts)
    end
  end
end