# -*- coding: utf-8 -*-

module Lyv

  # Checks if the length of score's music matches the lenght
  # of it's lyrics

  class LengthChecker

    include LilyPondTools

    # returns false if length of lyrics corresponds to the length of music,
    # otherwise returns Array of two Integers [music_length, lyrics_length]
    def check(score)
      m = music_length score
      l = lyrics_length score

      if m == l then
        return false
      else
        return [m, l]
      end
    end

    def music_length(score)
      m = score.music

      begin
        m_content = m[m.index('{')+1 .. m.rindex('}')-1]
      rescue NoMethodError
        # either brace not found
        return 0
      end

      # delete everything that we are not interesting in 
      # and could be interpreted as notes:
      # - comments (may include notes)
      m_content = delete_comments(m_content)
      # - key signature
      m_content = m_content.gsub(/\\key [cdefgab](is|es)? \\\w+/, '')

      l = 0
      in_melisma = false

      m_content.split(/\s+/).each do |token|
        /^[cdefgab](is|es)?[',]*[12486]{0,2}\.?[!\?]?([\(\)~])?([_\-\^].*)?$/.match(token) do |match|
          accidental, mel = match[1], match[2]

          if mel == '~' then
            next
          elsif mel == '(' then
            in_melisma = true
            next
          elsif mel == ')' then
            in_melisma = false
          elsif in_melisma then
            next
          end

          l += 1
        end
      end

      return l
    end

    def lyrics_length(score)
      delete_comments(score.lyrics_raw) \
        .gsub(/\\skip \d+/, 'xskipx') \
        .gsub(/\\markup\{[^}]*\}/, 'xmarkupx') \
        .strip \
        .split(/\s+/).select {|x| x != '--' }.size
    end
  end
end
