require 'java'
require File.dirname(__FILE__) + '/../vendor/httpcore-4.0.1.jar'
require File.dirname(__FILE__) + '/../vendor/httpcore-nio-4.0.1.jar'

# The Ruby module that contains wrappers for the the Apache
# HTTP NIO implementation.
module HttpReactor
end

$:.unshift(File.dirname(__FILE__))

require 'http_reactor/client'