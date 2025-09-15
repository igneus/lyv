# -*- coding: utf-8 -*-

module Lyv
  module LilyPond

    class Document

      def initialize(**args)
        [:scores, :preamble, :header].each do |prop|
          if args.has_key? prop
            instance_variable_set "@#{prop}", args[prop]
          end
        end

        @id_index = {}
        @scores.each do |s|
          sid = s.header['id']
          if [nil, ''].include? sid
            next
          end

          @id_index[sid] = s
        end
      end

      attr_reader :scores, :preamble, :header

      def [](i)
        if i.is_a? Integer
          return @scores[i]
        end

        @id_index[i]
      end

      def include_id?(i)
        @id_index.has_key? i
      end

      def ids_included
        @scores.collect {|s| s.header['id'] }
      end

    end
  end
end
