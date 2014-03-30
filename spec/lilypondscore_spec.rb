# -*- coding: utf-8 -*-

require_relative 'spec_helper'

module Lyv
  
  describe LilyPondScore do

    describe ".new" do
      before :each do
        @score_with_comments_source = '\score {
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
    psalmus = "Žalm 142" % comment comment
    id = "ne-1ne-a2"
    piece = \markup {\sestavTitulek}
  }
}'
        @score_with_comments = LilyPondScore.new @score_with_comments_source
      end

      it 'does not strip comments from source text' do
        @score_with_comments.text.should include '% Hle'
      end
      
      it 'strips comments from lyrics_raw' do
        @score_with_comments.lyrics_raw.should_not include '%'
        @score_with_comments.lyrics_raw.should eq 'Ej -- hle, Hos -- po -- din při -- jde'
      end

      it 'strips comments from lyrics_readable' do
        @score_with_comments.lyrics_readable.should_not include '%'
        @score_with_comments.lyrics_readable.should eq 'Ejhle, Hospodin přijde'
      end

      it 'strips comments following header fields' do
        @score_with_comments.header['psalmus'].should eq 'Žalm 142'
      end
    end
  end

end
