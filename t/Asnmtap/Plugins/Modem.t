use Test::More tests => 6;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Plugins::Modem' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Modem' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Modem', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Modem', qw(&get_modem_request) ) };

TODO: {
  use ASNMTAP::Asnmtap::Plugins v3.000.008;
  use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

  my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
    _programName        => 'check_template-modem.pl',
    _programDescription => "Modem plugin template for the '$APPLICATION'",
    _programVersion     => '3.000.008',
    _programGetOptions  => ['timeout|t:i', 'trendline|T:i'],
    _timeout            => 30,
    _debug              => 0);

  my ($returnCode, $errorStatus);

  $returnCode = get_modem_request ( asnmtapInherited => \$objectPlugins );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing phonenumber\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request(): Missing phonenumber');

  $returnCode = get_modem_request ( 
    asnmtapInherited => \$objectPlugins,
    phonenumber      => 'azerty'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QInvalid phonenumber\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::Modem::get_modem_request(): Invalid phonenumber');

  undef $objectPlugins;
}