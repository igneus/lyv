# -*- coding: utf-8 -*-

require_relative 'spec_helper'

module Lyv

  describe LengthChecker do

    before :each do
      @c = LengthChecker.new

      @simple_ly = "\\score { \\relative c' { a4 } }"
      @simple_score = LilyPondScore.new @simple_ly

      @notes_ly = "\\score { \\relative c' { a4 b c, d8. e'' f4 g4 a bes cis2 } }"
      @notes_score = LilyPondScore.new @notes_ly

      @melisma_ly = "\\score { \\relative c' { a4~ a b,( d) } }"
      @melisma_score = LilyPondScore.new @melisma_ly
    end

    describe '#music_length' do
      it 'copes with a simple score' do
        @c.music_length(@simple_score).should eq 1
      end

      it 'copes with a multiple-notes score' do
        @c.music_length(@notes_score).should eq 10
      end

      it 'counts melisma as one note' do
        @c.music_length(@melisma_score).should eq 2
      end
    end

    describe '#lyrics_length' do

    end

    describe '#check' do

    end
  end
end
