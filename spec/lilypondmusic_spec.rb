# -*- coding: utf-8 -*-

require_relative 'spec_helper'

module Lyv

  describe LilyPondMusic do

    describe ".new" do

      before :each do
        @test_fname = File.expand_path 'advent_responsoria.ly', EXAMPLES_DIR
        @test_fname2 = File.expand_path 'kompletar.ly', EXAMPLES_DIR
      end

      it 'loads from a string' do
        m = nil
        expect do
          m = LilyPondMusic.new '\score { \relative c\' { a a } \addlyrics { la -- la } }'
        end.not_to raise_error

        m.scores.size.should eq 1
      end

      it 'loads from a File' do
        m = nil
        expect do
          m = LilyPondMusic.new File.open @test_fname
        end.not_to raise_error

        m.scores.size.should be > 1
      end

      it 'loads from a file specified by name' do
        m = nil
        expect do
          m = LilyPondMusic.new @test_fname
        end.not_to raise_error

        m.scores.size.should be > 1
      end

      it 'sets source file for each score when loaded from a file' do
        m = LilyPondMusic.new @test_fname

        m.scores.first.src_file.should eq @test_fname
      end

      it 'starts a new row of default (numeric) score ids' do
        msrc = '\score { \relative c\' { a a } \addlyrics { la -- la } }'
        m1 = LilyPondMusic.new msrc
        m2 = LilyPondMusic.new msrc
        
        m1.scores.first.number.should eq 1
        m2.scores.first.number.should eq 1
      end

      it 'assigns scores subsequent numbers' do
        msrc = ('\score { \relative c\' { a a } \addlyrics { la -- la } }'+"\n") * 3
        m = LilyPondMusic.new msrc

        m.scores.size.should eq 3
        m.scores.each_with_index do |s,i|
          s.number.should eq i+1
        end
      end

      it 'loads a document with no scores without error' do
        m = LilyPondMusic.new ''
        m.scores.should eq []
      end
    end
  end

end
