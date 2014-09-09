require 'sqlite3'
require 'date'

module Lyv

  # make index of scores in a sqlite3 database
  class Index

    def initialize(fname, options={})
      @db = SQLite3::Database.new fname
      @options = options

      @dbg = true

      @columns = [
                  # fields copied from the LilyPondScore instance
                  :music, :lyrics_raw, :lyrics_readable, :src_file,
                  :number, :text,
                  # we must create ourselves
                  :created,
                 ]

      init_tables(true)

      if block_given? then
        yield self
      end
    end

    attr_accessor :dbg

    def add_score(score)
      data = {}
      @columns[0..5].each {|c| data[c] = score.send c }

      data['created'] = DateTime.now.iso8601

      cols = data.keys()
      cols_q = cols.collect {|c| c.to_s }
      vals_q = cols.collect {|c| quote_str(data[c]) }

      score.header.each_pair do |key, value|
        next if value.empty?

        cname = 'h_' + key
        unless has_column? cname
          add_column cname
        end
        cols_q << cname
        vals_q << quote_str(value)
      end

      query "INSERT INTO Scores (#{cols_q.join(', ')}) VALUES (#{vals_q.join(', ')});"
    end

    def add(music)
      music.scores.each {|s| add_score s }
    end

    def add_file(fname)
      return unless file_updated? fname

      query "DELETE FROM Scores WHERE src_file = #{quote_str(fname)}"

      add LilyPondMusic.new fname
    end

    private

    def file_updated?(fname)
      # do we already know the file?
      any = query "SELECT number FROM Scores WHERE src_file = #{quote_str(fname)};"
      return true if any.empty?

      # are there any scores older than the file's mtime?
      mt = File.mtime fname
      mt_iso = mt.strftime '%FT%T'
      older = query "SELECT number FROM Scores WHERE src_file = #{quote_str(fname)} AND created < #{quote_str(mt_iso)};"
      return true unless older.empty?

      return false
    end

    def has_column?(name)
      @columns.include? name.to_sym
    end

    def add_column(name)
      query "ALTER TABLE Scores ADD COLUMN #{name} TEXT;"
      @columns << name.to_sym
    end

    # quote and escape string to safely use it as a string literal in a query
    def quote_str(str)
      '"' + str.to_s.gsub(/"/, '""') + '"'
    end

    def init_tables(drop=false)
      cols = @columns.collect do |c|
        c.to_s + " text"
      end
      cols = cols.join ', '

      query "CREATE TABLE IF NOT EXISTS Scores (#{cols});"

      cols = query "PRAGMA table_info(Scores);"
      @columns += cols.collect {|c| c[1].to_sym }.select {|c| c.to_s.start_with? 'h_' }
    end

    def query(q, dbg=false)
      STDERR.puts q if (dbg or @dbg)
      r = @db.execute q
      p(r) if (dbg or @dbg)
      return r
    end
  end
end
