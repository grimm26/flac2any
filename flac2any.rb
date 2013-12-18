#!/usr/bin/ruby
#
#
require 'optparse'
require_relative 'ManipFlacs'

#main
flacs = ManipFlacs.new
# Default values
options = {}
begin
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    options[:format] = 'ogg';
    opts.on("--format FORMAT", "What format/codec to copy the flac to",flacs.FORMATS.to_a) do |format|
      options['format'] = format
    end
  end.parse!
  #STDERR.puts options.inspect

  if ARGV.length < 1
    raise "Please provide a format and a target directory or file."
  end
rescue Exception => e
  STDERR.puts e.message
  #STDERR.puts e.backtrace.inspect
end

ARGV.each do |fileordir|
  STDERR.puts "Processing #{fileordir}"
  flacs.add_flacs(fileordir)
end
flacs.convert_to(options['format'])

