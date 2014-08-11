# -*- coding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'lyv'
  s.version     = '0.0.0'
  #s.date        = '2014-07-20'
  s.summary     = "tools to work with simple lilypond scores"

  s.description = File.read 'README.md'

  s.authors     = ["Jakub Pavlík"]
  s.email       = 'jkb.pavlik@gmail.com'
  s.files       = Dir['bin/*.rb'] + Dir['lib/*.rb'] + Dir['lib/lyv/*.rb'] + Dir['spec/*.rb']
  s.executables = ['lyv']
  s.homepage    =
    'http://github.com/igneus/lyv'
  s.licenses    = ['LGPL-3.0', 'MIT']

  s.add_runtime_dependency 'thor'

  s.add_development_dependency "rspec", '~> 2.14'
end
