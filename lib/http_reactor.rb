require 'java'
require 'httpcore-4.0.1.jar'
require 'httpcore-nio-4.0.1.jar'

# The Ruby module that contains wrappers for the the Apache
# HTTP NIO implementation.
module HttpReactor
end

require 'http_reactor/request'
require 'http_reactor/response'
require 'http_reactor/client'