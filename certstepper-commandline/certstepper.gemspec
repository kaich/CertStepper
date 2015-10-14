Gem::Specification.new do |s|  
  s.name        = 'certstepper'  
  s.version     = '1.1.4'  
  s.date        = '2015-07-20'
  s.executables = %w{ certstepper }  
  s.summary     = "cert simplefy"  
  s.description = "create ios dev cert simple"  
  s.authors     = ["chengkai"]  
  s.email       = 'chengkai@1853.com'  
  s.files       = Dir["lib/*"]  +%w{ bin/certstepper}
  s.require_paths = %w{ lib }
  s.homepage    = 'http://rubygems.org/gems/certstepper'  
end  