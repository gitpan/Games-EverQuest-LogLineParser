=head1 NAME

Games::EverQuest::LogLineParser - Perl extension for parsing lines from the
EverQuest log file.

=head1 SYNOPSIS

   use Games::EverQuest::LogLineParser;

   my $eqlog_file = 'c:/everquest/eqlog_Soandso_veeshan.txt';

   open(my $eq_log_fh, $eqlog_file) || die "$eqlog_file: $!";

   while (<$eq_log_fh>)
      {
      my $parsed_line = parse_eq_line($_);
      next unless $parsed_line;
      do_something($parsed_line);
      }

=head1 DESCRIPTION

C<Games::EverQuest::LogLineParser> provides functions related to parsing the
interesting bits from an EverQuest log file.

=head2 Functions

=over 4

=item parse_eq_line($eq_line)

Returns a hash ref, containing variable keys depending on the type of line
that was passed as the first argument. if the line was not recognized, then
false is returned.

Two keys that will always be present, if the line was recognized, are
C<time_stamp> and C<line_type>. The first will contain the time string from
the line, while the latter will be a string indicating how the line was
classified. A given C<line_type> hash ref, will always contain the same keys,
though some of the values may be C<undef>.

Knowing the C<line_type> allows you to determine the keys from the
L<LINE TYPES> section below.

=item parse_eq_time_stamp($parsed_line->{'time_stamp'})

Given the C<time_stamp> value from a parsed line, returns a hash ref with the
following structure:

   ## sample input [Mon Oct 13 00:42:36 2003]
   {
    day   => 'Mon',
    month => 'Oct',
    date  => '13',
    hour  => '00',
    min   => '42',
    sec   => '36',
    year  => '2003',
   }

=item all_possible_keys()

Returns a list of all possible keys for the hash refs that are returned by C<parse_eq_line()>.

=back

=head1 EXPORT

By default the C<parse_eq_line> and C<parse_eq_time_stamp> subroutines are exported.

=head1 LINE TYPES

=over 4

=cut

package Games::EverQuest::LogLineParser;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw/ Exporter /;

our @EXPORT = qw/ parse_eq_line parse_eq_time_stamp all_possible_keys /;

our $VERSION = '0.01';

my (%line_types);

## returns a parsed line hash ref if the line is understood, else false
sub parse_eq_line
   {
   my ($line) = @_;

   return unless length $line > 28;

   my $time_stamp = substr($line, 0, 27, '');

   for my $line_type (keys %line_types)
      {
      if (my @parts = $line =~ $line_types{$line_type}{rx})
         {
         my $parsed_line = $line_types{$line_type}{handler}->(@parts);
         $parsed_line->{'time_stamp'} = $time_stamp;
         $parsed_line->{'line_type'}  = $line_type;
         return $parsed_line;
         }
      }

   return "miss";

   }

## parses the time_stamp into a hash ref
## sample input [Mon Oct 13 00:42:36 2003]
sub parse_eq_time_stamp
   {
   my ($time_stamp) = @_;

   $time_stamp =~ tr/][:/ /;

   my ($day, $month, $date, $hour, $min, $sec, $year) = split ' ', $time_stamp;

   return
      {
      day   => $day,
      month => $month,
      date  => $date,
      hour  => $hour,
      min   => $min,
      sec   => $sec,
      year  => $year
      };

   }

## returns all possible keys from the set of all parsed line hash refs
sub all_possible_keys
   {

   my %all_keys;

   for my $line_type (keys %line_types)
      {
      for my $key (keys %{ $line_types{$line_type}{handler}->() })
         {
         $all_keys{$key}++;
         }
      }

   return ( qw/ line_type time_stamp /, sort keys %all_keys );

   }


=item MELEE_DAMAGE

   input line:

      You slash a Bloodguard crypt sentry for 88 points of damage.

   output hash ref:

      {
         attacker => 'You',
         attack   => 'slash',
         attackee => 'A Bloodguard crypt sentry',
         amount   => '88',
      };

   comments:

      none

=cut

$line_types{'MELEE_DAMAGE'} =
   {
   rx      => qr/\A(.+?) (slash|hit|kick|pierce|bash|punch|crush|bite|maul)(?:s|es)? (?!by non-melee)(.+?) for (\d+) points? of damage\.\Z/,
   handler => sub
      {
      my ($attacker, $attack, $attackee, $amount) = @_;
      return
         {
         attacker => ucfirst $attacker,
         attack   => $attack,
         attackee => ucfirst $attackee,
         amount   => $amount,
         };
      }

   };

=item YOU_MISS_MOB

   input line:

      You try to kick a Bloodguard crypt sentry, but miss!

   output hash ref:

      {
         attack   => 'slash',
         attackee => 'A Bloodguard crypt sentry',
      };

   comments:

      none

=cut

$line_types{'YOU_MISS_MOB'} =
   {
   rx      => qr/\AYou try to (\w+) (.+?), but miss!\Z/,
   handler => sub
      {
      my ($attack, $attackee) = @_;
      return
         {
         attack   => $attack,
         attackee => ucfirst $attackee,
         };
      }
   };

=item MOB_HITS_YOU

   input line:

      A Bloodguard crypt sentry hits YOU for 161 points of damage.

   output hash ref:

      {
         attacker => 'A Bloodguard crypt sentry',
         attack   => 'hit',
         amount   => '161',
      };

   comments:

      none

=cut

$line_types{'MOB_HITS_YOU'} =
   {
   rx      => qr/\A(.+?) (slash|hit|kick|pierce|bash|punch|crush|bite|maul)(?:s|es) YOU for (\d+) points? of damage\.\Z/,
   handler => sub
      {
      my ($attacker, $attack, $amount) = @_;
      return
         {
         attacker => $attacker,
         attack   => $attack,
         amount   => $amount,
         };
      }

   };

=item MOB_MISSES_YOU

   input line:

      A Bloodguard crypt sentry tries to hit YOU, but misses!

   output hash ref:

      {
         attacker => 'A Bloodguard crypt sentry',
         attack   => 'hit',
      };

   comments:

      none

=cut

$line_types{'MOB_MISSES_YOU'} =
   {
   rx      => qr/\A(.+?) tries to (\w+) YOU, but misses!\Z/,
   handler => sub
      {
      my ($attacker, $attack) = @_;
      return
         {
         attacker => $attacker,
         attack   => $attack,
         };
      }
   };

=item FACTION_HIT

   input line:

      Your faction standing with Loyals got worse.

   output hash ref:

      {
         faction_group  => 'Loyals',
         faction_change => 'worse',
      };

   comments:

      none

=cut

$line_types{'FACTION_HIT'} =
   {
   rx      => qr/\AYour faction standing with (.+?) got (better|worse)\.\Z/,
   handler => sub
      {
      my ($faction_group, $faction_change) = @_;
      return
         {
         faction_group  => $faction_group,
         faction_change => $faction_change,
         };
      }

   };

=item YOU_REPEL_HIT

   input line:

      A Bloodguard crypt sentry tries to hit YOU, but YOU parry!

   output hash ref:

      {
         attacker => 'A Bloodguard crypt sentry',
         attack   => 'hit',
         repel    => 'parry',
      };

   comments:

      none

=cut

$line_types{'YOU_REPEL_HIT'} =
   {
   rx      => qr/\A(.+?) tries to (\w+) YOU, but YOU (\w+)!\Z/,
   handler => sub
      {
      my ($attacker, $attack, $repel) = @_;
      return
         {
         attacker => $attacker,
         attack   => $attack,
         repel    => $repel,
         };
      }

   };

=item MOB_REPELS_HIT

   input line:

      You try to slash a Bloodguard crypt sentry, but a Bloodguard crypt sentry ripostes!

   output hash ref:

      {
         attack   => 'slash',
         attackee => 'A Bloodguard crypt sentry',
         repel    => 'riposte',
      };

   comments:

      none

=cut

$line_types{'MOB_REPELS_HIT'} =
   {
   rx      => qr/\AYou try to (\w+) (.+?), but \2 (\w+)s!\Z/,
   handler => sub
      {
      my ($attack, $attackee, $repel) = @_;
      $repel ||= '';
      $repel = 'parry' if $repel eq 'parrie';
      return
         {
         attack   => $attack,
         attackee => ucfirst $attackee,
         repel    => $repel,
         };
      }

   };

=item SLAIN_BY_YOU

   input line:

      You have slain a Bloodguard crypt sentry!

   output hash ref:

      {
         slayee => 'A Bloodguard crypt sentry',
      };

   comments:

      none

=cut

$line_types{'SLAIN_BY_YOU'} =
   {
   rx      => qr/\AYou have slain (.+?)!\Z/,
   handler => sub
      {
      my ($slayee) = @_;
      return
         {
         slayee => ucfirst $slayee,
         };
      }

   };

=item SKILL_UP

   input line:

      You have become better at Abjuration! (222)

   output hash ref:

      {
         skill_upped => 'Abjuration',
         skill_value => '222',
      };

   comments:

      none

=cut

$line_types{'SKILL_UP'} =
   {
   rx      => qr/\AYou have become better at (.+?)! \((\d+)\)\Z/,
   handler => sub
      {
      my ($skill_upped, $skill_value) = @_;
      return
         {
         skill_upped => $skill_upped,
         skill_value => $skill_value,
         };
      }

   };

=item SLAIN_BY_OTHER

   input line:

      a Bloodguard crypt sentry has been slain by Soandso!

   output hash ref:

      {
         slayee => 'A Bloodguard crypt sentry',
         slayer => 'Soandso',
      };

   comments:

      none

=cut

$line_types{'SLAIN_BY_OTHER'} =
   {
   rx      => qr/\A(.+?) has been slain by (.+?)!\Z/,
   handler => sub
      {
      my ($slayee, $slayer) = @_;
      return
         {
         slayee => ucfirst $slayee,
         slayer => $slayer,
         };
      }

   };

=item CORPSE_MONEY

   input line:

      You receive 67 platinum, 16 gold, 20 silver and 36 copper from the corpse.

   output hash ref:

      {
         platinum  => '67',
         gold      => '16',
         silver    => '20',
         copper    => '36',
      };

   comments:

      none

=cut

$line_types{'CORPSE_MONEY'} =
   {
   rx      => qr/\AYou receive (.+?)from the corpse\.\Z/,
   handler => sub
      {
      my ($money) = @_;
      $money ||= '';
      $money =~ s/and//;
      my %moneys = reverse split '[ ,]+', $money;
      return
         {
         platinum  => $moneys{'platinum'} || 0,
         gold      => $moneys{'gold'}     || 0,
         silver    => $moneys{'silver'}   || 0,
         copper    => $moneys{'copper'}   || 0,
         };
      }

   };

=item DAMAGE_SHIELD

   input line:

      a Bloodguard crypt sentry was hit by non-melee for 8 points of damage.

   output hash ref:

      {
         attacker => 'A Bloodguard crypt sentry',
         amount   => '8',
      };

   comments:

      none

=cut

$line_types{'DAMAGE_SHIELD'} =
   {
   rx      => qr/\A(.+?) was hit by non-melee for (\d+) points? of damage\.\Z/,
   handler => sub
      {
      my ($attacker, $amount) = @_;
      return
         {
         attacker => ucfirst $attacker,
         amount   => $amount,
         };
      }

   };

=item DIRECT_DAMAGE

   input line:

      Soandso hit a Bloodguard crypt sentry for 300 points of non-melee damage.

   output hash ref:

      {
         attacker => 'Soandso',
         attackee => 'A Bloodguard crypt sentry',
         amount   => '300',
      };

   comments:

      none

=cut

$line_types{'DIRECT_DAMAGE'} =
   {
   rx      => qr/\A(.+?) hit (.+?) for (\d+) points? of non-melee damage\.\Z/,
   handler => sub
      {
      my ($attacker, $attackee, $amount) = @_;
      return
         {
         attacker => $attacker,
         attackee => ucfirst $attackee,
         amount   => $amount,
         };
      }

   };

=item DAMAGE_OVER_TIME

   input line:

      A Bloodguard crypt sentry has taken 3 damage from your Flame Lick.

   output hash ref:

      {
         attackee => 'A Bloodguard crypt sentry',
         amount   => '3',
         spell    => 'Flame Lick',
      };

   comments:

      none

=cut

$line_types{'DAMAGE_OVER_TIME'} =
   {
   rx      => qr/\A(.+?) has taken (\d+) damage from your (.+?)\.\Z/,
   handler => sub
      {
      my ($attackee, $amount, $spell) = @_;
      return
         {
         attackee => $attackee,
         amount   => $amount,
         spell    => $spell,
         };
      }

   };

=item LOOT_ITEM

   input line:

      --You have looted a Flawed Green Shard of Might.--

   output hash ref:

      {
         looter => 'You',
         item   => 'Flawed Green Shard of Might',
      };

   input line:

      --Soandso has looted a Tears of Prexus.--

   output hash ref:

      {
         looter => 'Soandso',
         item   => 'Tears of Prexus',
      };

   comments:

      none

=cut

$line_types{'LOOT_ITEM'} =
   {
   rx      => qr/\A--(\S+) (?:has|have) looted a (.+?)\.--\Z/,
   handler => sub
      {
      my ($looter, $item) = @_;
      return
         {
         looter => $looter,
         item   => $item,
         };
      }

   };

=item BUY_ITEM

   input line:

      You give 1 gold 2 silver 5 copper to Cavalier Aodus.

   output hash ref:

      {
         platinum  => 0,
         gold      => '1',
         silver    => '2',
         copper    => '4',
         merchant  => 'Cavalier Aodus',
      };

   comments:

      none

=cut

$line_types{'BUY_ITEM'} =
   {
   rx      => qr/\AYou give (.+?) to (.+?)\.\Z/,
   handler => sub
      {
      my ($money, $merchant) = @_;
      $money ||= '';
      my %moneys = reverse split ' ', $money;
      return
         {
         platinum  => $moneys{'platinum'} || 0,
         gold      => $moneys{'gold'}     || 0,
         silver    => $moneys{'silver'}   || 0,
         copper    => $moneys{'copper'}   || 0,
         merchant  => ucfirst $merchant,
         };
      }

   };

=item ENTERED_ZONE

   input line:

      You have entered The Greater Faydark.

   output hash ref:

      {
         zone => 'The Greater Faydark',
      };

   comments:

      none

=cut

$line_types{'ENTERED_ZONE'} =
   {
   rx      => qr/\AYou have entered (.+?)\.\Z/,
   handler => sub
      {
      my ($zone) = @_;
      return
         {
         zone => $zone,
         };
      }

   };

=item SELL_ITEM

   input line:

      You receive 120 platinum from Magus Delin for the Fire Emerald Ring(s).

   output hash ref:

      {
         platinum  => '120',
         gold      => 0,
         silver    => 0,
         copper    => 0,
         merchant  => 'Magus Delin',
         item      => 'Fire Emerald Ring',
      };

   comments:

      none

=cut

$line_types{'SELL_ITEM'} =
   {
   rx      => qr/\AYou receive (.+?) from (.+?) for the (.+?)\(s\)\.\Z/,
   handler => sub
      {
      my ($money, $merchant, $item) = @_;
      $money ||= '';
      my %moneys = reverse split ' ', $money;
      return
         {
         platinum  => $moneys{'platinum'} || 0,
         gold      => $moneys{'gold'}     || 0,
         silver    => $moneys{'silver'}   || 0,
         copper    => $moneys{'copper'}   || 0,
         merchant  => $merchant,
         item      => $item,
         };
      }
   };

=item SPLIT_MONEY

   input line:

      You receive 163 platinum, 30 gold, 25 silver and 33 copper as your split.

   output hash ref:

      {
         platinum  => '163',
         gold      => '30',
         silver    => '25',
         copper    => '33',
      };

   comments:

      none

=cut

$line_types{'SPLIT_MONEY'} =
   {
   rx      => qr/\AYou receive (.+?) as your split\.\Z/,
   handler => sub
      {
      my ($money) = @_;
      $money ||= '';
      $money =~ s/and//;
      my %moneys = reverse split '[ ,]+', $money;
      return
         {
         platinum  => $moneys{'platinum'} || 0,
         gold      => $moneys{'gold'}     || 0,
         silver    => $moneys{'silver'}   || 0,
         copper    => $moneys{'copper'}   || 0,
         };
      }

   };

=item SPLIT_MONEY

   input line:

      You have been slain by a Bloodguard crypt sentry!

   output hash ref:

      {
         slayer => 'A Bloodguard crypt sentry',
      };

   comments:

      none

=cut

$line_types{'YOU_SLAIN'} =
   {
   rx      => qr/\AYou have been slain by (.+?)!\Z/,
   handler => sub
      {
      my ($slayer) = @_;
      return
         {
         slayer => ucfirst $slayer,
         };
      }

   };

=item TRACKING_MOB

   input line:

      You begin tracking a Bloodguard crypt sentry.

   output hash ref:

      {
         trackee => 'A Bloodguard crypt sentry',
      };

   comments:

      none

=cut

$line_types{'TRACKING_MOB'} =
   {
   rx      => qr/\AYou begin tracking (.+?)\.\Z/,
   handler => sub
      {
      my ($trackee) = @_;
      return
         {
         trackee => ucfirst $trackee,
         };
      }

   };

=item YOU_CAST

   input line:

      You begin casting Ensnaring Roots.

   output hash ref:

      {
         spell => 'Ensnaring Roots',
      };

   comments:

      none

=cut

$line_types{'YOU_CAST'} =
   {
   rx      => qr/\AYou begin casting (.+?)\.\Z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         spell => $spell,
         };
      }

   };

=item YOUR_SPELL_RESISTED

   input line:

      Your target resisted the Ensnaring Roots spell.

   output hash ref:

      {
         spell => 'Ensnaring Roots',
      };

   comments:

      none

=cut

$line_types{'YOUR_SPELL_RESISTED'} =
   {
   rx      => qr/\AYour target resisted the (.+?) spell\.\Z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         spell => $spell,
         };
      }

   };

=item FORGET_SPELL

   input line:

      You forget Ensnaring Roots.

   output hash ref:

      {
         spell => 'Ensnaring Roots',
      };

   comments:

      none

=cut

$line_types{'FORGET_SPELL'} =
   {
   rx      => qr/\AYou forget (.+?)\.\Z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         spell => $spell,
         };
      }

   };

=item MEMORIZE_SPELL

   input line:

      You have finished memorizing Ensnaring Roots.

   output hash ref:

      {
         spell => 'Ensnaring Roots',
      };

   comments:

      none

=cut

$line_types{'MEMORIZE_SPELL'} =
   {
   rx      => qr/\AYou have finished memorizing (.+?)\.\Z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         spell => $spell,
         };
      }

   };

=item YOU_FIZZLE

   input line:

      Your spell fizzles!

   output hash ref:

      {
      };

   comments:

      none

=cut

$line_types{'YOU_FIZZLE'} =
   {
   rx      => qr/\AYour spell fizzles!\Z/,
   handler => sub
      {
      return
         {
         };
      }

   };

=item LOCATION

   input line:

      Your Location is -63.20, 3846.55, -42.76

   output hash ref:

      {
         coord_1 => '-63.20',
         coord_2 => '3846.55',
         coord_3 => '-42.76',
      };

   comments:

      none

=cut

$line_types{'LOCATION'} =
   {
   rx      => qr/\AYour Location is (.+?)\Z/,
   handler => sub
      {
      my ($location_coords) = @_;
      $location_coords ||= '';
      my @coords = split /[\s,]+/, $location_coords;
      return
         {
         coord_1 => $coords[0],
         coord_2 => $coords[1],
         coord_3 => $coords[2],
         };
      }

   };

=item YOU_SAY

   input line:

      You tell your party, 'can you say /pet get lost'

   output hash ref:

      {
         spoken => 'can you say /pet get lost',
      };

   comments:

      none

=cut

$line_types{'YOU_SAY'} =
   {
   rx      => qr/\AYour say, '(.+)'\Z/,
   handler => sub
      {
      my ($spoken) = @_;
      return
         {
         spoken => $spoken,
         };
      }

   };

=item OTHER_SAYS

   input line:

      Soandso says, 'I aim to please :)'

   output hash ref:

      {
         speaker => 'Soandso',
         spoken  => 'I aim to please :)',
      };

   comments:

      none

=cut

$line_types{'OTHER_SAYS'} =
   {
   rx      => qr/\A(.+?) says,? '(.+)'\Z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         speaker => $speaker,
         spoken  => $spoken,
         };
      }

   };

=item YOU_TELL_OTHER

   input line:

      You told Soandso, 'lol, i was waiting for that =)'

   output hash ref:

      {
         speakee => 'Soandso',
         spoken  => 'lol, i was waiting for that =)',
      };

   comments:

      none

=cut

$line_types{'YOU_TELL_OTHER'} =
   {
   rx      => qr/\AYou told (\w+), '(.+)'\Z/,
   handler => sub
      {
      my ($speakee, $spoken) = @_;
      return
         {
         speakee => $speakee,
         spoken  => $spoken,
         };
      }

   };

=item OTHER_TELLS_YOU

   input line:

      Soandso tells you, 'hows the adv?'

   output hash ref:

      {
         speaker => 'Soandso',
         spoken  => 'hows the adv?',
      };

   comments:

      none

=cut

$line_types{'OTHER_TELLS_YOU'} =
   {
   rx      => qr/\A(\w+) tells you, '(.+)'\Z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         speaker => $speaker,
         spoken  => $spoken,
         };
      }

   };

=item YOU_TELL_GROUP

   input line:

      You tell your party, 'will keep an eye out'

   output hash ref:

      {
         spoken => 'will keep an eye out',
      };

   comments:

      none

=cut

$line_types{'YOU_TELL_GROUP'} =
   {
   rx      => qr/\AYou tell your party, '(.+)'\Z/,
   handler => sub
      {
      my ($spoken) = @_;
      return
         {
         spoken => $spoken,
         };
      }

   };

=item OTHER_TELLS_GROUP

   input line:

      Soandso tells the group, 'Didnt know that, thanks info'

   output hash ref:

      {
         speaker => 'Soandso',
         spoken  => 'Didnt know that, thanks info',
      };

   comments:

      none

=cut

$line_types{'OTHER_TELLS_GROUP'} =
   {
   rx      => qr/\A(\w+) tells the group, '(.+)'\Z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         speaker => $speaker,
         spoken  => $spoken,
         };
      }

   };

=item OTHER_CASTS

   input line:

      Soandso begins to cast a spell.

   output hash ref:

      {
         caster => 'Soandso',
      };

   comments:

      none

=cut

$line_types{'OTHER_CASTS'} =
   {
   rx      => qr/\A(.+?) begins to cast a spell\.\Z/,
   handler => sub
      {
      my ($caster) = @_;
      return
         {
         caster => ucfirst $caster,
         };
      }

   };

=item CRITICAL_SCORE

   input line:

      Soandso scores a critical hit! (126)

   output hash ref:

      {
         attacker => 'Soandso',
         type     => 'hit',
         amount   => '126',
      };

   comments:

      none

=cut

$line_types{'CRITICAL_SCORE'} =
   {
   rx      => qr/\A(\w+) scores a critical (hit|blast)! \((\d+)\)\Z/,
   handler => sub
      {
      my ($attacker, $type, $amount) = @_;
      return
         {
         attacker => $attacker,
         type     => $type,
         amount   => $amount,
         };
      }

   };

=item PLAYER_HEALED

   input line:

      Soandso has healed you for 456 points of damage.

   output hash ref:

      {
         healer => 'Soandso',
         healee => 'you',
         amount => '456',
      };

   comments:

      none

=cut

$line_types{'PLAYER_HEALED'} =
   {
   rx      => qr/\A(\w+) (?:have|has) healed (\w+) for (\d+) points of damage.\Z/,
   handler => sub
      {
      my ($healer, $healee, $amount) = @_;
      return
         {
         healer => $healer,
         healee => $healee,
         amount => $amount,
         };
      }

   };

=item SAYS_OOC

   input line:

      Soandso says out of character, 'Stop following me :oP'

   output hash ref:

      {
         speaker => 'Soandso',
         spoken  => 'Stop following me :oP',
      };

   comments:

      none

=cut

$line_types{'SAYS_OOC'} =
   {
   rx      => qr/\A(\w+) says out of character, '(.+)'\Z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         speaker => $speaker,
         spoken  => $spoken,
         };
      }

   };

=item OTHER_SHOUTS

   input line:

      Soandso shouts, 'talk to vual stoutest'

   output hash ref:

      {
         speaker => 'Soandso',
         spoken  => 'talk to vual stoutest',
      };

   comments:

      none

=cut

$line_types{'OTHER_SHOUTS'} =
   {
   rx      => qr/\A(\w+) shouts, '(.+)'\Z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         speaker => $speaker,
         spoken  => $spoken,
         };
      }

   };

=item PLAYER_LISTING

   input line:

      [56 Outrider] Soandso (Half Elf) <The Foobles>

   output hash ref:

      {
         level => '56',
         class => 'Outrider',
         name  => 'Soandso',
         race  => 'Half Elf',
         guild => 'The Foobles',
         zone  => '',
      };

   input line:

      [65 Deceiver] Soandso (Barbarian) <The Foobles> ZONE: potranquility

   output hash ref:

      {
         level => '65',
         class => 'Deceiver',
         name  => 'Soandso',
         race  => 'Barbarian',
         guild => 'The Foobles',
         zone  => 'potranquility',
      };

   comments:

      none

=cut

$line_types{'PLAYER_LISTING'} =
   {
   rx      => qr/\A(?:AFK )?\[(\d+) (.+?)\] (\w+) \((.+?)\) (?:<(.+?)>)? ?(?:ZONE: (\w+))?\s*\Z/,
   handler => sub
      {
      my ($level, $class, $name, $race, $guild, $zone) = @_;
      return
         {
         level => ($level || ''),
         class => ($class || ''),
         name  => $name,
         race  => ($race  || ''),
         guild => ($guild || ''),
         zone  => ($zone  || ''),
         };
      }

   };

=item YOUR_SPELL_WEARS_OFF

   input line:

      Your Flame Lick spell has worn off.

   output hash ref:

      {
         spell => 'Flame Lick',
      };

   comments:

      none

=cut

$line_types{'YOUR_SPELL_WEARS_OFF'} =
   {
   rx      => qr/\AYour (.+?) spell has worn off\.\Z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         spell => $spell,
         };
      }

   };

=item WIN_ADVENTURE

   input line:

      You have successfully completed your adventure.  You received 22 adventure points.  You have 30 minutes to exit this zone.

   output hash ref:

      {
         amount => '22',
      };

   comments:

      none

=cut

$line_types{'WIN_ADVENTURE'} =
   {
   rx      => qr/\AYou have successfully completed your adventure.  You received (\d+) adventure points.  You have 30 minutes to exit this zone\.\Z/,
   handler => sub
      {
      my ($amount) = @_;
      return
         {
         amount => $amount,
         };
      }

   };

=item SPEND_ADVENTURE_POINTS

   input line:

      You have spent 40 adventure points.

   output hash ref:

      {
         amount => '40',
      };

   comments:

      none

=cut

$line_types{'SPEND_ADVENTURE_POINTS'} =
   {
   rx      => qr/\AYou have spent (\d+) adventure points\.\Z/,
   handler => sub
      {
      my ($amount) = @_;
      return
         {
         amount => $amount,
         };
      }

   };

=item GAIN_EXPERIENCE

   input line:

      You gain party experience!!

   output hash ref:

      {
         gainer => 'party',
      };

   input line:

      You gain experience!!

   output hash ref:

      {
         gainer => '',
      };

   comments:

      none

=cut

$line_types{'GAIN_EXPERIENCE'} =
   {
   rx      => qr/\AYou gain (?:(party) )?experience!!\Z/,
   handler => sub
      {
      my ($gainer) = @_;
      return
         {
         gainer => ($gainer || ''),
         };
      }

   };

1;
__END__

=back

=head1 AUTHOR

fooble, E<lt>fooble@cpan.orgE<gt>

=head1 TO DO

=over 4

=item - adaptive sorting

=item - user specified execution order

=item - default execution order (be sure merchant tells with prices get checked prior to regular tells)

=item - make sure MELEE_DAMAGE doesn't pick up some non-melee damage

=back

=head1 SEE ALSO

=cut

