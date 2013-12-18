require 'flacinfo'

class FlacCmdsError < StandardError
end

class ManipFlacs
  attr_accessor :flacs
  attr_reader :FORMATS

  # Also find totaltracks
  FLAC_TAGS = ['ARTIST','ALBUM','TITLE','DATE','TRACKNUMBER','GENRE']
  FORMATS   = ['ogg','m4a','aac','mp3']

  def initialize()
    @flacs = []
  end

  def add_flacs(dirfile)
    begin
      if File.directory?(dirfile)
        # Add the flacs in this dir to the @flacs array
        @flacs.concat(Dir.glob("#{dirfile}/*.flac"))
      elsif File.file?(dirfile)
        # Add this file to the @flacs array
        @flacs << dirfile
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
      @flacs.each do |flac|
        metaflac = FlacInfo.new(flac)
        FLAC_TAGS.each do |t|
          unless metaflac.hastag?(t)
            raise FlacInfoError, "#{flac} missing tag #{t}"   
          end
        end
        STDERR.print "Encoding #{flac} into "
        case format 
        when "ogg"
          oggenc = which('oggenc')
          outfile = flac.sub(/flac$/, 'ogg')
          STDERR.puts "#{outfile}"
          cmd = %Q!#{oggenc} --quiet -q5 -o "#{outfile}" -d "#{metaflac.tags['DATE']}" -a "#{metaflac.tags['ARTIST']}" -l "#{metaflac.tags['ALBUM']}" -t "#{metaflac.tags['TITLE']}" -N #{metaflac.tags['TRACKNUMBER']} -G "#{metaflac.tags['GENRE']}" -!
        when "mp3"
          lame = which('lame')
          outfile = flac.sub(/flac$/, 'mp3')
          STDERR.puts "#{outfile}"
          cmd = %Q!#{lame} --quiet --noreplaygain -q2 -b 256 --cbr --ty "#{metaflac.tags['DATE']}" --ta "#{metaflac.tags['ARTIST']}" --tl "#{metaflac.tags['ALBUM']}" --tt "#{metaflac.tags['TITLE']}" --tn #{metaflac.tags['TRACKNUMBER']} --tg '#{metaflac.tags['GENRE']}' --id3v2-only  - #{outfile}!
        when "m4a", "aac"
          ffmpeg = which('ffmpeg')
          outfile = flac.sub(/flac$/, 'm4a')
          STDERR.puts "#{outfile}"
          cmd = %Q!#{ffmpeg} -v fatal -i - -c:a libfdk_aac -vbr 4 -metadata title="#{metaflac.tags['TITLE']}" -metadata artist="#{metaflac.tags['ARTIST']}" -metadata date="#{metaflac.tags['DATE']}" -metadata album="#{metaflac.tags['ALBUM']}" -metadata track=#{metaflac.tags['TRACKNUMBER']} -metadata genre="#{metaflac.tags['GENRE']}" #{outfile}!
        else
          raise "Unknown format #{format}"
        end
        system %Q!#{flac_cmd} --decode --stdout --totally-silent "#{flac}" | #{cmd}!
      end
    rescue FlacInfoError => e
      STDERR.puts e.message
      STDERR.puts e.backtrace.inspect
    rescue FlacInfoReadError => e
      STDERR.puts e.message
      STDERR.puts e.backtrace.inspect
    rescue FlacCmdsError => e
      STDERR.print "Required command not found: "
      STDERR.puts e.message
      STDERR.puts e.backtrace.inspect
    end
  end

  #   which('ruby') #=> /usr/bin/ruby
  #   Should also check for supported features that we need, especially in ffmpeg
  def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable? exe
      }
    end
    raise FlacCmdsError, %Q!Could not locate "#{cmd}" for conversion.!
  end
end
