# -*- coding: utf-8 -*-

require_relative 'spec_helper'

module Lyv
  
  describe LilyPondScore do

    let :score_with_comments do
      LilyPondScore.new \
'\score {
  \relative c\'\' {
    \choralniRezim
    c a c c a g f \barMin
  }
  \addlyrics {
    % Hle, Pán při -- jde
    Ej -- hle, Hos -- po -- din při -- jde
  }
  \header {
    quid = "2. ant."
    modus = "V"
    differentia = "a"
    empty_property = ""
    multiline_property = "first line
    second line
third line"
    psalmus = "Žalm 142" % comment comment
    id = "ne-1ne-a2"
    piece = \markup {\sestavTitulek}
  }
}'
    end

    describe "#text" do
      it 'preserves comments' do
        score_with_comments.text.should include '% Hle'
      end
    end
      
    describe '#lyrics_raw' do
      it 'has comments stripped' do
        score_with_comments.lyrics_raw.should_not include '%'
        score_with_comments.lyrics_raw.should eq 'Ej -- hle, Hos -- po -- din při -- jde'
      end

      it 'handles nested braced expressions correctly' do
        score = LilyPondScore.new "\\score { \\relative c' { d } \\addlyrics { \\markup{mu mu} } }"
        score.lyrics_raw.should eq '\markup{mu mu}'
      end
    end

    describe '#lyrics_readable' do
      it 'has comments stripped' do
        score_with_comments.lyrics_readable.should_not include '%'
        score_with_comments.lyrics_readable.should eq 'Ejhle, Hospodin přijde'
      end
    end

    describe '#header' do
      it 'does not contain comments' do
        score_with_comments.header['psalmus'].should eq 'Žalm 142'
      end

      it 'handles multi-line value, preserves whitespace' do
        score_with_comments.header['multiline_property']
          .should eq "first line\n    second line\nthird line"
      end

      it 'handles empty property' do
        score_with_comments.header['empty_property'].should eq ''
      end
    end

    describe '#music' do
      it 'starts with the opening token of the music' do
        score_with_comments.music.should start_with "\\relative c''"
      end

      it 'ends with the closing brace' do
        score_with_comments.music.should end_with '}'
      end

      it 'contains music' do
        score_with_comments.music.should include '\choralniRezim'
        score_with_comments.music.should include 'c a c c a g f \barMin'
      end
    end
  end

end
