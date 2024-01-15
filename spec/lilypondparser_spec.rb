# -*- coding: utf-8 -*-

require_relative 'spec_helper'

module Lyv
  describe LilyPondParser do
    shared_examples 'header parsing' do
      describe 'simple header' do
        let(:header_src) { '\header { title = "My title" }' }
        it { expect(header['title']).to eq 'My title' }
      end

      describe 'multiple keys' do
        let(:header_src) { '\header { key = "a" key2 = "b" }' }
        it { expect(header['key']).to eq 'a' }
        it { expect(header['key2']).to eq 'b' }
      end

      describe 'header with newlines' do
        let(:header_src) { "\\header {\n  title = \"My title\" \n}" }
        it { expect(header['title']).to eq 'My title' }
      end

      describe 'comments' do
        let(:header_src) { "\\header { title = \"My title\" % comment \n}" }
        it { expect(header['title']).to eq 'My title' }
      end

      describe 'escaped quotes in value' do
        let(:header_src) { '\header { key = "hi\"ho" }' }
        it { expect(header['key']).to eq 'hi"ho' }
      end

      # this behavior is not ideal, but for now there's no need
      # to be able to parse these
      describe 'header fields with markup values are not parsed' do
        let(:header_src) { '\header { key = \markup{some \italic{formatted} text} }' }
        it { expect(header).not_to have_key 'key' }
      end
    end

    describe '#parse_document' do
      it 'returns LilyPondMusic' do
        expect(subject.parse_document('')).to be_a LilyPond::Document
      end

      it 'loads scores' do
        src = '\score {} \score {}'
        doc = subject.parse_document src
        expect(doc.scores.size).to eq 2
      end

      describe 'loads document header' do
        let(:document) { subject.parse_document(header_src) }
        let(:header) { document.header }

        include_examples 'header parsing'
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
        @score_with_comments = subject.parse_score @score_with_comments_source
      end

      it 'returns Score' do
        expect(subject.parse_score('\score {}')).to be_a LilyPond::Score
      end

      describe "parses text" do
        it 'preserves comments' do
          @score_with_comments.text.should include '% Hle'
        end

        it 'only contains the score without any additional characters' do
          # eventual whitespace at the beginning is left in order not to break
          # relative indentation
          src = '   \score {}   '
          expect(subject.parse_score(src).text).to eq '   \score {}'
        end
      end

      describe 'parses lyrics' do
        it 'has comments stripped' do
          @score_with_comments.lyrics_raw.should_not include '%'
          @score_with_comments.lyrics_raw.should eq 'Ej -- hle, Hos -- po -- din při -- jde'
        end

        it 'handles nested braced expressions correctly' do
          score = subject.parse_score "\\score { \\relative c' { d } \\addlyrics { \\markup{mu mu} } }"
          score.lyrics_raw.should eq '\markup{mu mu}'
        end

        it 'has comments stripped' do
          @score_with_comments.lyrics_pretty.should_not include '%'
          @score_with_comments.lyrics_pretty.should eq 'Ejhle, Hospodin přijde'
        end

        describe 'parses header' do
          let(:score_src) do
'\score {
  \relative c\'\' { c4 c }
  \addlyrics { A -- men. }
  ' + header_src + '
}'
          end
          let(:score) { subject.parse_score(score_src) }
          let(:header) { score.header }

          include_examples 'header parsing'
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
