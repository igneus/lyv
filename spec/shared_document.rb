shared_examples 'behavior shared by LilyPond::Document and LilyPondMusic' do
  describe '#[]' do
    it 'finds score by ID' do
      score = subject['ne-rch']
      #expect(score).to be_a Lyv::LilyPondScore
      expect(score.header['piece']).to eq 'neděle - ranní chvály (III)'
    end

    it 'finds score by numeric index' do
      score = subject[0]
      #expect(score).to be_a Lyv::LilyPondScore
      expect(score.header['piece']).to eq 'neděle - ranní chvály (III)'
    end

    describe 'unknown index' do
      [
        'unknown-index',
        90,
        nil,
        Object.new
      ].each do |i|
        it "fails on #{i.inspect}" do
          expect(subject[i]).to be nil
        end
      end
    end
  end

  describe '#include_id?' do
    it { expect(subject.include_id?('ne-rch')).to be true }
    it { expect(subject.include_id?('xxxxxx')).to be false }
    it { expect(subject.include_id?(1)).to be false }
    it { expect(subject.include_id?(nil)).to be false }
  end

  describe '#ids_included' do
    it { expect(subject.ids_included).to eq %w(ne-rch ne-ne fe-rch fe-ne) }
  end
end
