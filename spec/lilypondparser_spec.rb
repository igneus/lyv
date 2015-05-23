# -*- coding: utf-8 -*-

require_relative 'spec_helper'

module Lyv
  describe LilyPondParser do
    before :all do
      @parser = LilyPondParser.new
    end

    describe '#parse_document' do
      it 'returns LilyPondMusic' do
        expect(@parser.parse_document('')).to be_a LilyPond::Document
      end

      it 'loads scores' do
        src = '\score {} \score {}'
        doc = @parser.parse_document src
        expect(doc.scores.size).to eq 2
      end

      it 'loads document header' do
        src = '\header { title = "My title" }'
        doc = @parser.parse_document src

        expect(doc.header).not_to be_empty
        expect(doc.header['title']).to eq 'My title'
      end
    end

    describe '#parse_score' do
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
        @score_with_comments = @parser.parse_score @score_with_comments_source
      end

      it 'returns Score' do
        expect(@parser.parse_score('\score {}')).to be_a LilyPond::Score
      end

      describe "parses text" do
        it 'preserves comments' do
          @score_with_comments.text.should include '% Hle'
        end

        it 'only contains the score without any additional characters' do
          # eventual whitespace at the beginning is left in order not to break
          # relative indentation
          src = '   \score {}   '
          expect(@parser.parse_score(src).text).to eq '   \score {}'
        end
      end

      describe 'parses lyrics' do
        it 'has comments stripped' do
          @score_with_comments.lyrics_raw.should_not include '%'
          @score_with_comments.lyrics_raw.should eq 'Ej -- hle, Hos -- po -- din při -- jde'
        end

        it 'handles nested braced expressions correctly' do
          score = @parser.parse_score "\\score { \\relative c' { d } \\addlyrics { \\markup{mu mu} } }"
          score.lyrics_raw.should eq '\markup{mu mu}'
        end

        it 'has comments stripped' do
          @score_with_comments.lyrics_pretty.should_not include '%'
          @score_with_comments.lyrics_pretty.should eq 'Ejhle, Hospodin přijde'
        end

        describe 'parses header' do
          it 'does not contain comments' do
            @score_with_comments.header['psalmus'].should eq 'Žalm 142'
          end

          it 'handles escaped quotes' do
            s = '\score { \header { key = "hi\"ho" }}'
            score = @parser.parse_score s
            expect(score.header['key']).to eq 'hi"ho'
          end
        end

        describe 'parses music' do
          it 'starts with the opening token of the music' do
            @score_with_comments.music.should start_with "\\relative c''"
          end

          it 'ends with the closing brace' do
            @score_with_comments.music.should end_with '}'
          end

          it 'contains music' do
            @score_with_comments.music.should include '\choralniRezim'
            @score_with_comments.music.should include 'c a c c a g f \barMin'
          end
        end
      end
    end
  end
end
