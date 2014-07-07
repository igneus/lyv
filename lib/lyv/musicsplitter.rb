module Lyv

  # splits a LilyPond music file to many numbered files, one score per file
  class MusicSplitter

    def initialize(options)
      @options = options
    end

    def chunk_name(original_name, id)
      original_name.sub(/\.ly$/, "_#{id}.ly")
    end

    # code dealing with the filesystem

    def split_file(file, options={})
      options = updated_options(options)

      puts "file: #{file}" if options[:verbose]
      
      m = LilyPondMusic.new file
      m.scores.each_with_index do |score,i|        
        if options[:ids] then
          if score.header['id'] != nil then
            id = score.header['id']
          else
            id = i+1
            STDERR.puts "Warning: no header 'id' in a score, fallback to numbering: #{file}"
          end
        else
          id = i+1
        end
        chunk_path = chunk_name file, id
        
        if options[:'output-dir'] then
          chunk_path = File.join(options[:'output-dir'], File.basename(chunk_path))
        end

        output = yield score
        
        puts "  writing to file #{chunk_path}" if options[:verbose]
        File.open(chunk_path, "w") do |fw|
          fw.puts output
        end
      end

      return m
    end

    # code dealing with the chunk contents

    def split_scores(file, options={})
      options = updated_options(options)

      split_file(file, options) do |score|
        scoretext = score.text
        
        if options[:'remove-headers'] then
          puts "  removing headers" if options[:verbose]
          ih = scoretext.index("\\header")
          i1 = scoretext.index '{', ih if ih
          if i1 then
            i2 = LilyPondScore.index_matching_brace(scoretext, i1)
            newtext = scoretext.slice(0,ih)+scoretext.slice(i2+1, scoretext.size-1)
          else
            newtext = scoretext
          end
        else
          newtext = scoretext
        end
        
        # remove eventual variable assignment
        varassignment = /^\s*\w+\s*=\s*\\score/ 
        if newtext =~ varassignment then
          newtext.gsub!(varassignment, '\score')
        end
        
        # This chunk is very In adiutorium - specific.
        if options[:'mode-info'] then
          i = newtext.index "\\relative"
          i = newtext.index '{', i if i
          unless i
            puts newtext
            raise "Couldn't find, where notes begin, couldn't thus insert mode info (score no. #{score.number})."
          end
          
          
          if score.header['quidbreve'] then
            quid = score.header['quidbreve']
          else
            quid = score.header['quid']
            if quid and quid.size > 8 then
              quid = quid.split(/\s+/).shift
            end
          end
          
          # Why are both "mode.differentia" and "quid" in quotation marks?
          # Because - even if one of them contains a space, we want to avoid line-break.
          case quid
          when /ant/
            puts "  adding mode information to score" if options[:verbose]
            modinfo = "\n\\set Staff.instrumentName = \\markup {
        \\center-column { \\bold { \"#{score.header['modus']}.#{score.header['differentia']}\" } \"#{quid}\" }
      }"
            newtext[i+1] = modinfo
          when /resp/
            puts "  adding mode information to score" if options[:verbose]
            modinfo = "\n\\set Staff.instrumentName = \\markup {
        \\center-column { \\bold { \"#{score.header['modus']}\" } \"#{quid}\" }
      }"
            newtext[i+1] = modinfo
          end
        end
        
        if options[:'prepend-text']  then
          puts "  prepending given text" if options[:verbose]
          newtext = options[:'prepend-text'] + "\n" + newtext
        end
        
        if options[:'insert-text'] then
          puts "  inserting given text" if options[:verbose]
          i = newtext.rindex "}"
          newtext[i-1] = options[:'insert-text']
        end
        
        yield newtext, score if block_given?
        
        newtext
      end
    end

    alias_method :split, :split_scores

    private

    def updated_options(options)
      return @options.dup.update(options)
    end
  end
end
