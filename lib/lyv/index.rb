require 'sqlite3'

module Lyv

  class Index

    def initialize(fname, options={})
      @db = SQLite3::Database.new fname
      @options = options

      @dbg = true

      @columns = [:music, :lyrics_raw, :lyrics_readable, :created, :file]

      init_tables(true)

      if block_given? then
        yield self
      end
    end

    attr_accessor :dbg

    def add_score(score)
      data = {}
      @columns[0..2].each {|c| data[c] = score.send c }

      cols = data.keys()
      cols_q = cols.collect {|c| c.to_s }.join(', ')
      vals_q = cols.collect {|c| "\"#{data[c]}\""}.join(', ')
      query "INSERT INTO Scores (#{cols_q}) VALUES (#{vals_q});"
    end

    def add(music)
      # if there is a not yet known header field, add column to the table!
      music.scores.each {|s| add_score s }
    end

    private

    def init_tables(drop=false)
      cols = @columns.collect do |c|
        len = 64
        if c.to_s.include? 'lyrics' then
          len = 512
        end

        c.to_s + " varchar(#{len})"
      end
      cols = cols.join ', '

      query "CREATE TABLE Scores (#{cols});"
    end

    def query(q, dbg=false)
      STDERR.puts q if (dbg or @dbg)
      @db.execute q
    end
  end
end
