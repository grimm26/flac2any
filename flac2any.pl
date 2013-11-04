#!/usr/bin/perl -w

# take a given file or directory and convert flac file(s) to supplied format.

use feature "say";
use Audio::FLAC::Header;
use Getopt::Long qw(GetOptions);
use strict;

# Default codec is ogg
my $codec = 'ogg';
my $result = GetOptions ("codec|format=s" => \$codec
                 );
# There should be a usage message.
exit unless $result;                 

&verify_codec($codec) or
        die "codec $codec unsupported.\n";

my $in = shift;
my $rh_flacs = &get_flacs($in);

while (my ($flac, $rh_tags) = each %$rh_flacs) {
  my $utitle = $rh_tags->{'TITLE'};
  $utitle =~ s/\s+/_/g;
  my $out = sprintf("%02d-%s.%s",$rh_tags->{'TRACKNUMBER'},$utitle,$codec);
  print "$flac to $out\n";
  my $encoder_cmd = &get_encoder_cmd($codec,$rh_tags,$out);
  print "flac --decode --stdout --silent \"$flac\" | $encoder_cmd\n";
  system "flac --decode --stdout --silent \"$flac\" | $encoder_cmd";
}


sub get_encoder_cmd {
    my $codec = shift;
    my $tags  = shift;
    my $out   = shift;

    my $cmd;
    if ($codec eq "mp3") {
        $cmd = qq!lame --noreplaygain -q 2 -b 256 --cbr --ty $tags->{'YEAR'} --ta "$tags->{'ARTIST'}" --tl "$tags->{'ALBUM'}" --tt "$tags->{'TITLE'}"  --tn $tags->{'TRACKNUMBER'} --tg "$tags->{'GENRE'}" --id3v2-only - $out!;
    } elsif ($codec eq "ogg") {
        $cmd = qq!oggenc -o "$out" -d $tags->{'YEAR'} -a "$tags->{'ARTIST'}" -l "$tags->{'ALBUM'}" -t "$tags->{'TITLE'}" -q 5 -N $tags->{'TRACKNUMBER'} -G "$tags->{'GENRE'}" -!;
    }

    return $cmd;
}

sub get_flacs {
    my $fileordir = shift;

    my @flacs = ();
    if (-d $fileordir) {
        # Scan directory
        opendir IN,$fileordir;
        my @files = grep /\.flac$/,readdir IN;
        closedir IN;
        @flacs = map { "$fileordir/". $_ } @files;
    } elsif (-f $fileordir) {
        @flacs = ( $fileordir );
    } else {
        die "Supplied arg is not a file or directory\n";
    }

    #DATE: 2008
    #ARTIST: Opeth
    #ALBUM: Watershed
    #TITLE: Coil
    #GENRE: Progressive Metal
    #TRACKNUMBER: 01
    my %flacs;
    foreach my $flac (@flacs) {
        my $header = Audio::FLAC::Header->new($flac);
        my $rh_tags = $header->tags();
        if (my $rl_missing = &normalize_tags($rh_tags)) {
            say "$flac: missing tags ". join ", ",@$rl_missing;
            exit 1;
        }
        $flacs{$flac} = $rh_tags;
    }
    return \%flacs;
}

sub normalize_tags {
    my $rh_tags = shift;

    my @normals = ('ARTIST','TITLE','ALBUM');
    my @missing = ();
    foreach my $tag (@normals) {
        unless (defined $rh_tags->{$tag}) {
            push @missing,$tag;
        }
    }
    if (defined $rh_tags->{'DATE'}) {
        $rh_tags->{'YEAR'} = $rh_tags->{'DATE'};
    } elsif (not defined $rh_tags->{'YEAR'}) {
        push @missing, "DATE or YEAR";
    }
    if (defined $rh_tags->{'TRACK'}) {
        $rh_tags->{'TRACKNUMBER'} = $rh_tags->{'TRACK'};
    } elsif (not defined $rh_tags->{'TRACKNUMBER'}) {
        push @missing, "TRACK or TRACKNUMBER";
    }

    if ($#missing > -1) {
        return \@missing;
    }
}

sub verify_codec {
    my $codec = shift;

    my $valid = 0;
    # Should probably actually check of we have binaries for the codec.
    if ($codec eq 'ogg' or $codec eq 'mp3') {
        $valid++;
    }
    return $valid;
}

