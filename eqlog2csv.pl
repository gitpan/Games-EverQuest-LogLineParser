## convert an EverQuest log file to a CSV (actually '|' separated) file

use strict;
use warnings;

use Games::EverQuest::LogLineParser;

die "USAGE: perl eqlog2csv.pl <eqlog_file> [output_file]\n" unless @ARGV > 0;

my ($eqlog_file, $output_file) = @ARGV;

$output_file = defined $output_file ? $output_file : '-';

open (my $eqlog_fh,  $eqlog_file)     || die "$eqlog_file: $!";
open (my $output_fh, ">$output_file") || die "$output_file: $!";

my @headers = all_possible_keys();

print $output_fh join('|', @headers), "\n";

while (<$eqlog_fh>)
   {

   my $line = parse_eq_line($_);

   if ($line)
      {

      no warnings 'uninitialized';

      $_ =~ tr/|//d for values %{ $line };

      print $output_fh join('|', @{ $line }{ @headers }), "\n";

      }

   }

close $eqlog_fh;
close $output_fh;