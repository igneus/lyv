module Lyv
  module LilyPond

    class Score

      def initialize(**args)
        [:text, :lyrics_raw, :lyrics_pretty, :music, :header, :number, :src_file].each do |prop|
          if args.has_key? prop
            instance_variable_set "@#{prop}", args[prop]
          end
        end
      end

      # complete source of the score
      attr_reader :text

      # score lyrics as included in the source file, only with comments stripped
      attr_reader :lyrics_raw

      # score lyrics stripped of lilypond syllabification
      attr_reader :lyrics_pretty

      # music
      attr_reader :music

      # Hash containing header fields
      attr_reader :header

      # position of the score in the file
      attr_reader :number

      # name/path of the source file - only if loaded from a file
      attr_reader :src_file

      def to_s
        "#{@src_file}#" + \
          ((@header['id'] != nil && @header['id'].size > 0) ?
           @header['id'] : @number).to_s
      end

    end
  end
end
