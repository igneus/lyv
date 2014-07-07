
%w{ lilypondmusic lilypondscore musicsplitter }.each do |lib|
  require_relative File.join 'lyv', lib
end
