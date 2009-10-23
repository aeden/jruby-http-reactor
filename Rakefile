require 'rake'
require 'rake/rdoctask'

desc 'Default: run tests.'
task :default => [:test]

desc 'Run tests.'
task :test do
  require File.dirname(__FILE__) + '/test/client_test'
end

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'JRuby HTTP Reactor'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "jruby-http-reactor"
    gemspec.summary = "JRuby NIO HTTP client."
    gemspec.email = "anthonyeden@gmail.com"
    gemspec.homepage = "http://github.com/aeden/jruby-http-reactor"
    gemspec.description = ""
    gemspec.authors = ["Anthony Eden"]
    gemspec.files.exclude 'docs/**/*'
    gemspec.files.exclude '.gitignore'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
