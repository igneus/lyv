# -*- coding: utf-8 -*-

module Lyv

  # Checks if the length of score's music matches the lenght
  # of it's lyrics

  class LengthChecker

    def check(score)

    end

    def check_music(music)

    end

    def check_file(path)

    end

    def music_length(score)
      m = score.music
      m_content = m[m.index('{')+1 .. m.rindex('}')-1]
      return m_content.scan(/[cdefgab](is|es)?[',]*[12486]{0,2}/).size
    end

    def lyrics_length(score)

    end
  end
end
