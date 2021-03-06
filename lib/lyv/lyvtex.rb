# -*- coding: utf-8 -*-

require 'lyv/scoremodifier'

require 'pslm'
require 'ostruct'
require 'yaml'

module Lyv

  # Preprocesses a .lyvtex file and creates a .lytex file
  # for further processing by lilypond-book and some flavour of latex.
  #
  # The lyvtex 'macros' insert lilypond and gregorio scores,
  # pslm psalms and further resources which often have to be built
  # (compiled, separated, ...) first. LyvTeX takes the burden
  # of building these resources from the shoulders of the typographer.

  # It doesn't descend into eventual included tex files, so you have
  # to preprocess these separately if needed.

  class LyvTeX

    @@default_setup = {
      :chant_basedir => '.',
      :psalms_dir => '.',
      :includes => [],
      :generated_dir => 'generovane',
      :output_dir => 'vystup',
      :doxology => false,
      :remove_optional_alleluia => false,
      :result_suffix => 'lytex'
    }

    def initialize(fpath, options={})
      options = @@default_setup.copy.update(options)
      @setup = OpenStruct.new options

      @psalmpreprocessor_setup = ::StructuredSetup.new({
        :general => {
          :format => 'latex', # latex|pslm
        },
        :input => {
          :has_title => true,
          :join => true,
        },
        :output => Pslm::Outputter::DEFAULT_SETUP.dup
      })
      @psalmpreprocessor_setup[:output][:pointing].delete :accents
      @psalmpreprocessor_setup[:output][:pointing].delete :preparatory
      @psalmpreprocessor_setup.update({
                                        :output => {
                                          :lettrine => { :digraphs => ['ch'] },
                                          :quote => :guillemets,
                                          :strophes => {
                                            :end_marks => :semantic,
                                            :paragraph_space => false
                                          }
                                        }
                                      })

      @psalm_counter = 0
      @psalm_suffix_size = 5

      @musicsplitter_setup = {
        :remove_headers => true,
        :prepend_text => '',
        :output_dir => @setup.generated_dir,
        :ids => true,
        :mode_info => true,
        :verbose => false,
        :insert_text => nil,
        :one_clef => false
      }

      @current_chant_source = nil

      @split_music_files = {}

      @doxology_noappend = ['kantikum_dan3iii.zalm', 'kantikum_zj19.zalm']

      init_psalmpreprocessor
      init_musicsplitter
      make_dirs

      process_lyvtex fpath

      @last_psalm_tone = nil
    end

    class << self
      alias :preprocess :new
    end

    private

    def make_dirs
      [:generated_dir, :output_dir].each do |d|
        if ! FileTest.directory?(@setup.send(d)) then
          Dir.mkdir @setup.send(d)
        end
      end
    end

    def init_psalmpreprocessor
      @psalmpreprocessor = Pslm::PsalmPointer.new(@psalmpreprocessor_setup)
    end

    def init_musicsplitter
      @musicsplitter_setup[:output_dir] = @setup.generated_dir

      prepend_text = @setup.includes.collect do |inc|
        # ../ because the paths are relative to the source but here we need them
        # relative to the output directory.
        # This solution is quite dirty and not universally working ...
        "\\include \"../#{inc}\""
      end
      prepend_text = prepend_text.join("\n")
      @musicsplitter_setup[:prepend_text] = prepend_text

      @splitter = MusicSplitter.new(@musicsplitter_setup)
    end

    def load_config(ymlf)
      conf = YAML.load(File.open(ymlf))
      pp = ms = false

      if conf.include? 'typographus' then
        conf['typographus'].each_pair do |k,v|
          @setup[k.to_sym] = v
        end
        pp = ms = true

        if @setup[:doxology] == 'full' then
          @psalmpreprocessor_setup[:append_text] = File.read(@setup.psalms_dir + '/doxologie.zalm')
        elsif @setup[:doxology] then
          @psalmpreprocessor_setup[:append_text] = "\\nopagebreak Sláva Otci."
        end
      end

      if conf.include? 'psalmpreprocessor' then
        conf['psalmpreprocessor'].each_pair do |k,v|
          @psalmpreprocessor_setup[k.to_sym] = v
        end
        pp = true
      end

      if conf.include? 'splitscores' then
        conf['splitscores'].each_pair do |k,v|
          @musicsplitter_setup[k.to_sym] = v
        end
        ms = true
      end

      init_psalmpreprocessor if pp
      init_musicsplitter if ms
    end

    def expand_macros(l)

      # test macro

      l.gsub!(/\\printHi/) do
        '% Hi hey hello, Typographus seems to work!'
      end

      # setup macros (empty output)

      l.gsub!(/\\setConfig\{(.*)\}/) do
        load_config $1
        ''
      end

      l.gsub!(/\\setChantBasedir\{(.*)\}/) do
        @setup.chant_basedir = $1
        init_musicsplitter # reinitialization needed
        ''
      end

      l.gsub!(/\\setPsalmsDir\{(.*)\}/) do
        @setup.psalms_dir = $1
        ''
      end

      l.gsub!(/\\setTmpDir\{(.*)\}/) do
        @setup.generated_dir = $1
        make_dirs
        ''
      end

      l.gsub!(/\\setChantSource\{(.*)\}/) do
        @current_chant_source = $1
        split_music_file @current_chant_source
        ''
      end

      l.gsub!(/\\setIncludes\{(.*)\}/) do
        unless @split_music_files.empty?
          STDERR.puts "Warning: setting common includes when some music files " +
            "(#{@split_music_files.keys.join(', ')}) are already processed."
        end
        incs = $1.split(',').collect {|s| s.strip}
        @setup.includes += incs
        init_musicsplitter # reinitialization needed
        ''
      end

      # expanded macros

      l.gsub!(/\\simpleScore\{(.*)\}/) do
        prepare_generic_score($1) + "\n\n"
      end

      l.gsub!(/\\responsory\{(.*)\}/) do
        prepare_generic_score($1) + "\n\n"
      end

      l.gsub!(/\\antiphon\{(.*)\}/) do
        prepare_generic_score($1) + "\n\n"
      end

      l.gsub!(/\\antiphonWithPsalm\{(.*)\}/) do
        r = prepare_generic_score($1) + "\n\n"
        if @setup[:psalm_tones] then
          r += prepare_psalm_tone_f($1) + "\n\n"
        end
        r += wrap_psalmody { prepare_psalm_f($1) }
        r
      end

      # TODO see the todo file for how the gregorio scores should be
      # handled in the future
      l.gsub!(/\\gregorioScore\{(.*)\}/) do
        prepare_gregorio_score($1) + "\n\n"
      end

      l.gsub!(/\\psalm\{([^\}]*)\}(\{([^\}]*)\})*/) do
        psalm_tone = $3
        psalm_tone = @last_psalm_tone if psalm_tone == '' or psalm_tone == nil
        @last_psalm_tone = psalm_tone

        r = ''
        if @setup[:psalm_tones] then
          r += prepare_psalm_tone_(psalm_tone) + "\n\n"
        end
        r += wrap_psalmody { prepare_psalm($1, psalm_tone) }
        r
      end

      # \psalmGroup{Žalm 1}...{Žalm n}{VIII.G} (tone optional)
      l.gsub!(/\\psalmGroup(\{.*\})/) do
        args = $1.split(/[\}\{]+/)
        args.delete ""
        p args

        psalm_tone = nil
        psalm_tone = args.pop if args.last.include? '.' # weak condition!
        psalm_tone = @last_psalm_tone if psalm_tone == '' or psalm_tone == nil
        @last_psalm_tone = psalm_tone

        psalms = args

        r = ''
        if @setup[:psalm_tones] then
          r += prepare_psalm_tone(psalm_tone) + "\n\n"
        end
        r += wrap_psalmody do
          psalms.collect {|p| prepare_psalm(p, psalm_tone) }.join("\n")
        end
        r
      end

      return l
    end

    def prepare_generic_score(fial)
      src, id = decode_fial fial

      src_name = File.basename(src)
      score_path = @setup.generated_dir + '/' + @splitter.chunk_name(src_name, id)

      score = get_score(src, id)
      if is_antiphon?(score) and score.header['modus'] then
        @last_psalm_tone = "#{score.header['modus']}.#{score.header['differentia']}"
      end

      return "\\lilypondfile{#{score_path}}"
    end

    def prepare_gregorio_score(path)
      compiled_path = path.sub(/\.gabc$/, '.tex')
      `gregorio #{path}`
      return "\\includescore{#{compiled_path}}"
    end

    def prepare_psalm(psalm_name, tone)
      psalmf = psalm_fname(psalm_name)
      gloriapatri = File.join @setup.psalms_dir, 'doxologie.zalm'
      processed = File.join(@setup.generated_dir, File.basename(psalmf).sub(/\.zalm$/, '_'+psalm_unique_suffix+'.tex'))

      psalm_sources = []
      if not File.exist? psalmf then
        # try to find the psalm's parts and compose them
        1.upto(3) do |i|
          psalm_part_f = psalmf.sub(/\.zalm$/, 'i'*i + '.zalm')
          if File.exist? psalm_part_f then
            psalm_sources << psalm_part_f
          end
        end

        if psalm_sources.size > 0 then
          STDERR.puts "Warning: #{psalm_name} not found, but successfully composed from discovered parts of the same text: #{psalm_sources.join(' ')}; you'd better check the output."
        end
      else
        psalm_sources << psalmf
      end

      if @setup.doxology and
          not @doxology_noappend.include?(File.basename(psalmf)) then
        psalm_sources << gloriapatri
      end

      pslmpointer_opts = {
        :output => { :pointing => {:tone => tone} }
      }

      @psalmpreprocessor.process(psalm_sources, processed, pslmpointer_opts) do |ps|
        if psalm_sources.size > 2 then # psalm composed from parts
          # part title to title of the whole psalm; only works for psalms
          ps.header.title.gsub!(/^\s*([^\s]+\s+[\d\w]+).*$/) { $1 }
        end
      end

      `vlna #{processed}`
      return "\\input{#{processed}}"
    end

    # prepares psalm according to the header information of a score
    # identified by it's FIAL

    def prepare_psalm_f(fial)
      src, id = decode_fial fial

      if @split_music_files[src][id].nil? then
        raise "Score with id '#{src}##{id}' not found."
      end

      score = @split_music_files[src][id]
      if score.header['psalmus'].nil? or score.header['psalmus'] == '' then
        raise "Psalm information not found in score #{score}."
      end

      if score.header['modus'] != nil then
        tone = "#{score.header['modus']}.#{score.header['differentia']}"
      else
        tone = ''
      end

      return prepare_psalm score.header['psalmus'], tone
    end

    def wrap_psalmody
      "\\begin{psalmodia}\n" +
        yield +
        "\\end{psalmodia}\n"
    end

    def prepare_psalm_tone(tone)
      tone = tone.gsub('.', '-')
      return prepare_generic_score 'psalmodie.ly#'+tone
    end

    def prepare_psalm_tone_f(fial)
      src, id = decode_fial fial

      score = @split_music_files[src][id]
      mod = score.header['modus'].gsub(' ', '')
      diff = score.header['differentia'].gsub('*', 'x').gsub(' ', '')
      psalm_tone = "#{mod}-#{diff}"

      return prepare_generic_score 'psalmodie.ly#'+psalm_tone
    end

    # converts a Czech psalm name how it is customarily used in the project
    # to a psalm file name

    def psalm_fname(name)
      name = name.downcase.gsub(' ', '').gsub('-', '').tr('áéíóúůýžščřďťňÁÉÍÓÚŮÝŽŠČŘĎŤŇ', 'aeiouuyzscrdtnaeiouuyzscrdtn')

      if name !~ /^zalm/ then
        name = 'kantikum_' + name
      end

      return File.join @setup.psalms_dir, "#{name}.zalm"
    end

    # looks for a score; raises error if it is not loaded

    def get_score(file, score_id)
      unless @split_music_files.include? file
        raise "#{file} music file not found."
      end

      unless @split_music_files[file].include_id? score_id
        raise "score ##{score_id} not found in file #{file}. Found [#{@split_music_files[file].ids_included.join(' ')}]"
      end

      return @split_music_files[file][score_id]
    end

    # takes fial, returns a path and an id or raises exception

    def decode_fial(fial)
      if fial[0] != '#' then
        begin
          fial_parsed = FIAL.new(fial)
        rescue
          raise "Failed to read fial '#{fial}'."
        end
        src = fial_parsed.path
        id = fial_parsed.id

        unless @split_music_files.include? src
          split_music_file src
        end
      else
        if @current_chant_source.nil? then
          raise "Relative chant reference '#{fial} found, but no chant source set.'"
        end

        src = @current_chant_source
        id = fial[1..-1]
      end

      return src, id
    end

    # accepts "FIAL path" relative to the music base directory

    def split_music_file(path)
      if @split_music_files.include? path then
        return
      end

      full_path = File.join @setup.chant_basedir, path
      # the values of @split_music_files are LilyPondMusic instances
      @split_music_files[path] = @splitter.split_scores(full_path) do |score_text, score|
        process_score score_text, score
      end
    end

    # processes a score (once source file has been split)
    # before it is saved to a chunk file; produces a string - valid
    # lilypond source
    def process_score(score_text, score)
      layout = []

      # remove optional alleluia

      if @setup[:remove_optional_alleluia] and
          is_antiphon? score then
        score_text = ScoreModifier.remove_optional_alleluia score_text
      end

      # no indent for scores of types without mode info
      unless is_antiphon?(score) or is_responsory?(score)
        layout << 'indent = 0'
      end

      unless layout.empty?
        score_text = ScoreModifier.layout score_text, layout.join("\n")
      end

      return score_text
    end

    def process_lyvtex(fpath)
      outfile = fpath.sub(/\.\w*tex$/, @setup.result_suffix)
      File.open(outfile, 'w') do |out|

        File.open(fpath) do |f|
          li = 0
          f.each_line do |l|
            li += 1
            begin
              out.print expand_macros(l)
            rescue => ex
              STDERR.puts "lyvtex: #{fpath}:#{li}: #{ex.message} (#{ex.class})"
              raise
            end
          end
        end

      end
    end

    def psalm_unique_suffix
      r = @psalm_counter.to_s.rjust @psalm_suffix_size, '0'
      @psalm_counter += 1
      return r
    end

    def is_antiphon?(score)
      score.header['quid'] and score.header['quid'].downcase.include? 'ant'
    end

    def is_responsory?(score)
      score.header['quid'] and score.header['quid'].downcase.include? 'resp'
    end

  end
end

