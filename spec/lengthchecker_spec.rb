# -*- coding: utf-8 -*-

require_relative 'spec_helper'

module Lyv

  describe LengthChecker do

    before :each do
      @c = LengthChecker.new

      @simple_ly = "\\score { \\relative c' { a4 } }"
      @simple_score = LilyPondScore.new @simple_ly

      @notes_ly = "\\score { \\relative c' { a4 b c, d8. e'' f4 g4 a bes cis2 } \\addlyrics { a -- hoj a -- no ne la -- la -- la moo_m -- tsa } }"
      @notes_score = LilyPondScore.new @notes_ly

      @melisma_ly = "\\score { \\relative c' { a4~ a b,( c e c d) } }"
      @melisma_score = LilyPondScore.new @melisma_ly

      @real_ly = <<-EOS
\\score {
  \\relative c'' {
    \\choralniRezim
    g4 a g b c d c \\barMaior
    c4( b a) b c( d) e d \\barMin
    d4 f e d( c) a b a g g \\barFinalis
  }
  \\addlyrics {
    Hos -- po -- di -- ne, slyš můj hlas,
    ja -- ko ka -- di -- dlo ať k_to -- bě stou -- pá má mo -- dlit -- ba.
  }
  \\header {
    quid = "1. ant."
    modus = "VII"
    differentia = "a"
    psalmus = "Žalm 141"
    id = "1ne-ant1"
    piece = \\markup {\\sestavTitulek}
  }
}
EOS
      @real_score = LilyPondScore.new @real_ly
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

      it 'does not count variables' do
        var_ly = "\\score { \\relative c' { \\choralniRezim g4 a \\barMaior } }"
        var_score = LilyPondScore.new var_ly
        @c.music_length(var_score).should eq 2
      end

      it 'copes with a real score' do
        @c.music_length(@real_score).should eq 21
      end

      it 'does not count key signature' do
        key_ly = "\\score { \\relative c' { \\key f \\major } }"
        key_score = LilyPondScore.new key_ly
        @c.music_length(key_score).should eq 0
      end

      it 'handles correctly note with markup' do
        markup_score = LilyPondScore.new "\\score { \\relative c' { d^\\markup\\rubrVelikAleluja } }"
        @c.music_length(markup_score).should eq 1
      end

      it 'ignores comments' do
        comment_score = LilyPondScore.new "\\score { \\relative c' { % d e \n } }"
        @c.music_length(comment_score).should eq 0
      end

      it 'handles ? and ! correctly' do
        score = LilyPondScore.new "\\score { \\relative c' { bes? bes! } }"
        @c.music_length(score).should eq 2
      end
    end

    describe '#lyrics_length' do
      it 'works well' do
        @c.lyrics_length(@notes_score).should eq 10
      end

      it 'copes with a real score' do
        @c.lyrics_length(@real_score).should eq 21
      end

      it 'ignores comments' do
        comment_score = LilyPondScore.new "\\score { \\relative c' { d } \\addlyrics { % mu \n } }"
        @c.lyrics_length(comment_score).should eq 0
      end

      it 'skip counts as one syllable' do
        skip_score = LilyPondScore.new "\\score { \\relative c' { d } \\addlyrics { \\skip 1 } }"
        @c.lyrics_length(skip_score).should eq 1
      end
    end
  end
end
