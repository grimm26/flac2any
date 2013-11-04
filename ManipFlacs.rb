require 'flacinfo'

class ManipFlacs
  attr_accessor :flacs

  FLAC_TAGS = ['ARTIST','ALBUM','TITLE','DATE','TRACKNUMBER','GENRE']

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
    print "@flacs: "
    begin
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
          outfile = flac.sub(/flac$/, 'ogg')
          STDERR.puts "#{outfile}"
          cmd = %Q!oggenc -q5 -o "#{outfile}" -d "#{metaflac.tags['DATE']}" -a "#{metaflac.tags['ARTIST']}" -l "#{metaflac.tags['ALBUM']}" -t "#{metaflac.tags['TITLE']}" -N #{metaflac.tags['TRACKNUMBER']} -G "#{metaflac.tags['GENRE']}" -!
        when "mp3"
          outfile = flac.sub(/flac$/, 'mp3')
          STDERR.puts "#{outfile}"
          cmd = %Q!lame --noreplaygain -q2 -b 256 --cbr --ty "#{metaflac.tags['DATE']}" --ta "#{metaflac.tags['ARTIST']}" --tl "#{metaflac.tags['ALBUM']}" --tt "#{metaflac.tags['TITLE']}" --tn #{metaflac.tags['TRACKNUMBER']} --tg '#{metaflac.tags['GENRE']}' --id3v2-only  - #{outfile}!
        else
          raise "Unknown format #{format}"
        end
        system %Q!flac --decode --stdout --silent "#{flac}" | #{cmd}!
      end
    rescue FlacInfoError => e
      puts e.message
    rescue FlacInfoReadError => e
      puts e.message
    end
  end
end
