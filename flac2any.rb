#!/usr/bin/ruby
#
#
require 'optparse'
require_relative 'ManipFlacs'

#main
# Default values
options = Hash['format' => 'ogg']
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("--format FORMAT", "What format/codec to copy the flac to") do |f|
    options['format'] = f
  end
end.parse!

begin
  if ARGV.length < 1
    raise "Please provide a format and a target directory or file."
  end
rescue Exception => e
  STDERR.puts e.message
  #STDERR.puts e.backtrace.inspect
end

flacs = ManipFlacs.new
ARGV.each do |fileordir|
  STDERR.puts "Processing #{fileordir}"
  flacs.add_flacs(fileordir)
end
flacs.convert_to(options['format'])

