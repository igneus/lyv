
%w{ lilypondmusic lilypondscore musicsplitter lengthchecker }.each do |lib|
  require_relative File.join 'lyv', lib
end
