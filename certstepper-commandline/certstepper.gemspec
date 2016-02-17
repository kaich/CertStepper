Gem::Specification.new do |s|  
  s.name        = 'certstepper'  
  s.version     = '1.2.3'  
  s.date        = '2016-01-17'
  s.executables = %w{ certstepper }  
  s.summary     = "cert simplefy"  
  s.description = "create ios dev cert simple"  
  s.authors     = ["chengkai"]  
  s.email       = 'chengkai@1853.com'  
  s.files       = Dir["lib/*"]  +%w{ bin/certstepper}
  s.require_paths = %w{ lib }
  s.homepage    = 'http://rubygems.org/gems/certstepper'  

  s.add_runtime_dependency "cert" , '~> 1.2', '>= 1.2.8'
  s.add_runtime_dependency 'sigh', '~> 1.3', '>= 1.3.0'
  s.add_runtime_dependency 'produce' , '~> 1.1', '>= 1.1.1'
  s.add_runtime_dependency 'colorize' , '~> 0.7', '>= 0.7.7'
end  