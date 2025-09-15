# musicreader.rb

# Tools to 'parse' lilypond files containing one or more simple scores
# (isn't able to handle variables; only recognizes lyrics entered using
# \addlyrics; ...) and access their data, especially lyrics and header

module Lyv
  # Parses a lilypond file;
  # provides access to its scores
  class LilyPondMusic

    def initialize(src)
      @scores = []
      @id_index = {}
      @preamble = ''
      @score_counter = 0

      if src.is_a? IO then
        load_from src
      elsif src.is_a? String and File.exist? src then
        load_from File.open(src, "r"), src
      elsif src.is_a? String then
        load_from StringIO.new src
      else
        raise ArgumentError.new("Unable to load LilyPond music from #{src.inspect}.")
      end
    end

    attr_reader :scores
    attr_reader :preamble

    def [](i)
      if i.is_a? Fixnum then
        return @scores[i]
      elsif i.is_a? String then
        return @id_index[i]
      end
    end

    def include_id?(i)
      @id_index.has_key? i
    end

    def ids_included
      @scores.collect {|s| s.header['id'] }
    end

    private

    def create_score(store, src_name)
      @score_counter += 1
      begin
        score = LilyPondScore.new(store, src_name, @score_counter)
        @scores << score
        if score.header.has_key? 'id' then
          @id_index[score.header['id']] = score
        end
      rescue
        puts "Error in score:"
        puts store
        puts
        raise
      end
    end

    def load_from(stream, src_name='')
      store = ''
      beginning = true
      while (l = stream.gets)
        if l =~ /\\score\s*\{/ then
          if beginning then
            beginning = false
            @preamble = store
            store = l
            next
          else
            create_score store, src_name
            store = l
          end
        else
          store += l
        end
      end

      # last score:
      if beginning then
        @preamble = store
      else
        create_score store, src_name
      end
    end
  end
end
