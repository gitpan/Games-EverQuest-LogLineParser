## print all unrecognized lines in an EverQuest log file

use strict;
use warnings;

use Games::EverQuest::LogLineParser;

die "USAGE: perl eqlog_unrecognized_lines.pl <eqlog_file> [output_file]\n" unless @ARGV > 0;

my ($eqlog_file, $output_file) = @ARGV;

$output_file = defined $output_file ? $output_file : '-';

open (my $eqlog_fh,  $eqlog_file)     || die "$eqlog_file: $!";
open (my $output_fh, ">$output_file") || die "$output_file: $!";

while (<$eqlog_fh>)
   {

   parse_eq_line($_) || print $output_fh $_;

   }

close $eqlog_fh;
close $output_fh;