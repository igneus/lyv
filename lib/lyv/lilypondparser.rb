# -*- coding: utf-8 -*-

module Lyv
  # it isn't called NaiveLilyPondParser only because
  # there isn't any less naive one in Lyv.
  # This one is so naive, that it doesn't deserve
  # the name of a parser.

  class LilyPondParser

    # parses a String as music (possibly a lot of scores
    # and other content), returns LilyPondMusic
    def parse_music(str)
      return LilyPondMusic.new ''
    end

    # parses a String as one score (only handles the first
    # score found), returns LilyPondScore
    def parse_score(str)
      text_ii = find_braced_exp 'score', str, true
      if text_ii.nil?
        return nil
      end
      text = str[text_ii]

      music = braced_exp("(relative|absolute)(\s+[a-hA-H][,']*)?", text) || ''

      lyrics = braced_exp_content(braced_exp('addlyrics', text) || '')
      lyrics = strip_comments lyrics
      lyrics.strip!

      header_text = braced_exp_content(braced_exp('header', text) || '')
      header = parse_key_value header_text

      return LilyPond::Score.new(
                                 :text => text,
                                 :music => music,
                                 :lyrics_raw => lyrics,
                                 :lyrics_pretty => pretty_lyrics(lyrics),
                                 :header => header,
                                )
    end

    private

    # finds first occurrence of lilypond construct
    # \exp_name { ... }
    # in the given string and returns a Range of string indices
    def find_braced_exp(exp_name, str, leading_whitespace=false)
      start_regexp = /\\#{exp_name}\s*\{/
      match = start_regexp.match str
      if match.nil?
        return nil
      end

      start_token = match.to_s
      start_i = str.index(start_token)
      opening_brace_i = start_i + start_token.size - 1
      closing_brace_i = matching_brace_index str, opening_brace_i

      if leading_whitespace
        while start_i > 0 && str[start_i - 1] =~ /\s/
          start_i -= 1
        end
      end

      return start_i .. closing_brace_i
    end

    # finds first occurrence of a braced lilypond expression
    # and returns it as a string
    def braced_exp(exp_name, str, leading_whitespace=false)
      ii = find_braced_exp(exp_name, str, leading_whitespace)
      if ii.nil?
        return nil
      end
      return str[ii]
    end

    # expects a String containing a single braced
    # expression. Returns it's content.
    def braced_exp_content(str)
      start_i = str.index '{'
      end_i = str.rindex '}'
      if start_i.nil? or end_i.nil?
        return ''
      end

      return str[start_i + 1 .. end_i - 1]
    end

    # finds index of a brace matching a brace at index start
    def matching_brace_index(str, start)
      braces_stack = [start]
      i = start+1
      loop do
        io = str.index '{', i
        ic = str.index '}', i

        unless ic
          raise "No more closing brace found in the given string, #{braces_stack.size} braces still open."
        end

        if io &&  io < ic then
          braces_stack.push io
          i = io+1
        else
          braces_stack.pop
          i = ic+1
        end

        if braces_stack.empty? then
          return ic
        end
      end
    end

    def strip_comments(str)
      str.gsub(/%.*$/, '')
    end

    # turns LilyPond syllabified lyrics into human-readable lyrics
    def pretty_lyrics(lyrics)
      return lyrics.gsub(' -- ', ''). # syllable-separators
        gsub('_', ' '). # preposition-separators
        gsub(/\\\w+/, ''). # LilyPond variables
        gsub(/\s+/, ' '). # whitespace
        strip # leading and trailing whitespace
    end

    # expects String containing key-value pairs in the syntax
    # LilyPond uses in \header blocks; returns a Hash
    def parse_key_value(str)
      r = {}
      while true
        m = str.match /([\w_]+)\s*=/
        if m.nil?
          break
        end
        key = m[1]

        val_start = str.index '"'
        if val_start.nil?
          break
        end
        val_end = val_start

        # find end quote, handle escaped quotes
        begin
          val_end = str.index '"', val_end+1
        end while str[val_end-1] == "\\"

        if val_end.nil?
          val_end = -1
        end

        value = str[val_start + 1 .. val_end - 1]
        value.gsub!('\"', '"') # unescape quotes
        r[key] = value

        str = str[val_end + 1 .. -1]
      end

      return r
    end
  end
end
