## report on the counts of line types in an EverQuest log file

use strict;
use warnings;

use Games::EverQuest::LogLineParser;

die "USAGE: perl eqlog_line_type_frequency.pl <eqlog_file> [output_file]\n" unless @ARGV > 0;

my ($eqlog_file, $output_file) = @ARGV;

$output_file = defined $output_file ? $output_file : '-';

open (my $eqlog_fh,  $eqlog_file)     || die "$eqlog_file: $!";

my %freq;

while (<$eqlog_fh>)
   {

   (my $line = parse_eq_line($_)) || next;

   $freq{ $line->{'line_type'} } ++;

   }

close $eqlog_fh;

open (my $output_fh, ">$output_file") || die "$output_file: $!";

for (sort keys %freq)
   {
   printf $output_fh "   %-24s => %s\n", $_, $freq{$_};
   }

close $output_fh;