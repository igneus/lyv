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

      l = 0
      in_melisma = false
      m_content.scan(/[cdefgab](is|es)?[',]*[12486]{0,2}([\(\)~])?/) do |accidental, mel|
        if mel == '~' then
          next
        elsif mel == '(' then
          in_melisma = true
          next
        elsif mel == ')' then
          in_melisma = false
        end

        l += 1
      end

      return l
    end

    def lyrics_length(score)

    end
  end
end
