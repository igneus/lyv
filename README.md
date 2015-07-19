# lyv

*lyv* is a small set of tools to handle [LilyPond](http://lilypond.org) data
from Ruby.
It is in no way general. Most of it was first written for my
[In adiutorium](https://github.com/igneus/In-adiutorium) project
and subsequently used also in other contexts.
Thus the gem is primarily for my own purposes and available to anyone
who might happen to need it.

It solves tasks like
* how many scores are defined in a given file?
* what, if any, are their lyrics?
* which header fields do they have? With what values?
* which fields does the top-level header have?
* get whole source of the n-th score or score meeting some requirements

```ruby
require 'lyv'

parser = LilyPondParser.new
doc = parser.parse_document(File.read('path/to/MyMusic.ly'))

# top-level header fields
puts "#{doc.header['composer']}: #{doc.header['title']}"

# traverse scores and process their header fields and lyrics
doc.scores.each do |s|
  puts "#{s.header['opus']}: #{s.lyrics}"
end
```

## anti-advertisement

If you want to process LilyPond files, you should consider the fact that
most of the notation geeks seem to prefer Python as their scripting
language. Particularly the [python-ly](https://github.com/wbsoft/python-ly)
library might fit your needs.

If python-ly was there at the time my need to parse, split, rearrange,
programatically modify etc. LilyPond files emerged, I wouldn't have created
any of the scripts that later became lyv.

## license

GNU/GPL 3.0 or newer

## the name

*Liv* is a women's name of Nordic origin. 
*ly* is an extension commonly used for Li*ly*pond files.
