# lyv

*lyv* is a small set of tools to handle [LilyPond](http://lilypond.org) data
from Ruby.
It is in no way general. Most of it was first written for my
[In adiutorium](https://github.com/igneus/In-adiutorium) project
and subsequently used also in other contexts.
Thus the gem is primarily for my own purposes and available to anyone
who might happen to need it.

Problems it copes with:
* I need to obtain information contained in LilyPond files - like lyrics or header fields
* I have a set of scores in one LilyPond file and want to insert each one at a given place of a LaTeX document without manually moving it to a separate file

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
