# -*- coding: utf-8 -*-

module Lyv

  # small general tools for handling of lilypond source
  module LilyPondTools
    
    def delete_comments(ly_str)
      ly_str.split("\n").collect {|l| l.sub(/%.*$/, '') }.join("\n").strip
    end
  end
end
