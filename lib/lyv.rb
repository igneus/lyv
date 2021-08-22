# -*- coding: utf-8 -*-

require 'stringio'

%w{
lilypondtools lilypondmusic lilypondscore
musicsplitter lengthchecker
lilypondparser
}.each do |lib|
  require_relative File.join 'lyv', lib
end

%w{
score document
}.each do |lib|
  require_relative File.join 'lyv', 'lilypond', lib
end
