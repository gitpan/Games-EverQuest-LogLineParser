use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Games::EverQuest::LogLineParser',
    'VERSION_FROM' => 'LogLineParser.pm',
    'PREREQ_PM'    => { 'Test::More' => 0 },
    'EXE_FILES'    => [ 'eqlog2csv.pl' ],
    ($] >= 5.005 ? (ABSTRACT_FROM => 'LogLineParser.pm',
                    AUTHOR        => 'fooble <fooble@cpan.org>') : ()),
);
