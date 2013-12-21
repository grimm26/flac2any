require 'flacinfo'

class FlacCmdsError < StandardError
end

class ManipFlacs
  attr_accessor :flacs

  def initialize()
    @flacs = Hash.new
  end

  def add_flacs(dirfile)
    begin
      if File.directory?(dirfile)
        # Add the flacs in this dir to the @flacs array
        #@flacs.concat(Dir.glob("#{dirfile}/*.flac"))
        Dir.glob("#{dirfile}/*.flac").sort.each do |file|
         @flacs[file] = get_tags(file)
        end
      elsif File.file?(dirfile)
        # Add this file to the @flacs array
        #@flacs << dirfile
        @flacs[dirfile] = get_tags(dirfile)
      else
        raise "#{dirfile} is not a valid file or directory"
      end
    rescue RuntimeError => e
      STDERR.puts e.message
    end
  end

  def convert_to(format)
    begin
      flac_cmd = which('flac')
      @flacs.each do |flac,tags|
        STDERR.print "Encoding #{flac} into "
        # Need to check that we have the tags we need.
        # Use a lambda to set up args depending on format.
        case format 
        when "ogg"
          oggenc = which('oggenc')
          outfile = flac.sub(/flac$/, 'ogg')
          STDERR.puts "#{outfile}"
          cmd = %Q!#{oggenc} --quiet -q5 -o "#{outfile}" -d "#{tags[:date]}" -a "#{tags[:artist]}" -l "#{tags[:album]}" -t "#{tags[:title]}" -N #{tags[:track]} -G "#{tags[:genre]}" -!
          STDERR.puts "#{cmd}"
        when "mp3"
          lame = which('lame')
          outfile = flac.sub(/flac$/, 'mp3')
          STDERR.puts "#{outfile}"
          cmd = %Q!#{lame} --quiet --noreplaygain -q2 -b 256 --cbr --ty "#{tags[:date]}" --ta "#{tags[:artist]}" --tl "#{tags[:album]}" --tt "#{tags[:title]}" --tn #{tags[:track]} --tg '#{tags[:genre]}' --id3v2-only  - #{outfile}!
        when "m4a", "aac"
          ffmpeg = which('ffmpeg')
          outfile = flac.sub(/flac$/, 'm4a')
          STDERR.puts "#{outfile}"
          cmd = %Q!#{ffmpeg} -v fatal -i - -c:a libfdk_aac -vbr 4 -metadata title="#{tags[:title]}" -metadata artist="#{tags[:artist]}" -metadata date="#{tags[:date]}" -metadata album="#{tags[:album]}" -metadata track=#{tags[:track]} -metadata genre="#{tags[:genre]}" #{outfile}!
        else
          raise "Unknown format #{format}"
        end
        system %Q!#{flac_cmd} --decode --stdout --totally-silent "#{flac}" | #{cmd}!
      end
    rescue RuntimeError => e
      STDERR.puts e.message
      #STDERR.puts e.backtrace.inspect
    rescue FlacInfoError => e
      STDERR.puts e.message
      #STDERR.puts e.backtrace.inspect
    rescue FlacInfoReadError => e
      STDERR.puts e.message
      #STDERR.puts e.backtrace.inspect
    rescue FlacCmdsError => e
      STDERR.print "Required command not found: "
      STDERR.puts e.message
      #STDERR.puts e.backtrace.inspect
    end
  end

  private
  #   which('ruby') #=> /usr/bin/ruby
  #   Should also check for supported features that we need, especially in ffmpeg
  def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable? exe
      end
    end
    raise FlacCmdsError, %Q!Could not locate "#{cmd}" for conversion.!
  end

  def get_tags(flacfile)
    tags = Hash.new
    FlacInfo.new(flacfile).tags.each do |key, value|
      case key
      when 'TITLE'
        tags.merge!(title: value)
      when 'ALBUM'
        tags.merge!(album: value)
      when 'DATE', 'YEAR'
        tags.merge!(date: value)
      when 'ARTIST'
        tags.merge!(artist: value)
      when 'TRACK','TRACKNUMBER'
        tags.merge!(track: value)
      when 'TOTALTRACKS'
        tags.merge!(totaltracks: value)
      when 'GENRE'
        tags.merge!(genre: value)
      end
    end
    return tags
  end


end
