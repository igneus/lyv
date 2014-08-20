require 'sqlite3'

module Lyv

  class Index

    def initialize(fname, options={})
      @db = SQLite3::Database.new
      @options = options

      init_tables

      if block_given? then
        yield self
      end
    end

    def add(music)
      # if there is a not yet known header field, add column to the table!
    end

    private

    def init_tables
      # create table Scores: music, lyrics, standard header fields, date, file, id in the file
    end
  end
end
