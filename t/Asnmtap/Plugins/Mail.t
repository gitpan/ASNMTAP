use Test::More tests => 7;

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Mail' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Mail', qw(:ALL) ) };

TODO: {
  use ASNMTAP::Asnmtap::Plugins v3.000.008;
  use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS %STATE);

  $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
    _programName        => 'check_template.pl',
    _programDescription => "General plugin template for the '$APPLICATION'",
    _programVersion     => '3.000.008',
    _programGetOptions  => ['environment|e:s', 'timeout|t:i', 'trendline|T:i'],
    _timeout            => 30,
    _debug              => 0);

  isa_ok( $objectPlugins, 'ASNMTAP::Asnmtap::Plugins' );
  can_ok( $objectPlugins, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
  can_ok( $objectPlugins, qw(appendPerformanceData browseragent clientCertificate pluginValue pluginValues proxy timeout setEndTime_and_getResponsTime write_debugfile call_system exit) );

  my $body = "\nThis is the body of the email !!! ...\n";

  use ASNMTAP::Asnmtap::Plugins::Mail v3.000.008;

  $objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
    _asnmtapInherited => \$objectPlugins,
    _SMTP             => { smtp => [ qw(smtp.citap.be) ], mime => 0 },
    _mailType         => 0,
    _mail             => {
                           from   => 'alex.peeters@citap.com',
                           to     => 'asnmtap@citap.com',
                           status => $APPLICATION .' Status UP',
                           body   => $body
                         }
  );

  isa_ok( $objectMAIL, 'ASNMTAP::Asnmtap::Plugins::Mail' );
  can_ok( $objectMAIL, qw(sending_fingerprint_mail) );

  undef $objectMAIL;
  undef $objectPlugins;
}