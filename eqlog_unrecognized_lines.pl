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

__END__
=head1 NAME

eqlog_unrecognized_lines.pl - Perl script that prints lines from an EverQuest
log file, which are unparsable by L<Games::EverQuest::LogLineParser>.

=head1 SYNOPSIS

   ## output to STDOUT
   eqlog_eqlog_unrecognized_lines.pl c:\everquest\eqlog_Soandso_server.txt

      or

   ## output to file
   eqlog_eqlog_unrecognized_lines.pl c:\everquest\eqlog_Soandso_server.txt eqlog.csv

=head1 DESCRIPTION

C<eqlog_eqlog_unrecognized_lines.pl> prints lines from an EverQuest log file,
which are unparsable by L<Games::EverQuest::LogLineParser>.

This is useful if in finding new line types which should be added to the
module.

=head1 AUTHOR

fooble, E<lt>fooble@cpan.orgE<gt>

=head1 TO DO

=over 4

=item - show progress

=item - report lines per second

=item - report percent/count lines (un)recognized

=back

=head1 SEE ALSO

L<Games::EverQuest::LogLineParser>

=cut

