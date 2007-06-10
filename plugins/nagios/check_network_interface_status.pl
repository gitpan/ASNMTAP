#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/04/06, v1.0, check_network_interface_status.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use lib qw(. /export/home/nagios/cpan-shared/lib/perl5/. /opt/supervision/cpan-shared/lib/perl5/.);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.000.012;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_network_interface_status.pl',
  _programDescription => 'Network Interface Status',
  _programVersion     => '1.0',
  _programUsagePrefix => '--interface=<interface>',
  _programHelpPrefix  => '--interface=<interface>',
  _programGetOptions  => ['interface|i=s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $interface = $objectNagios->getOptionsArgv ('interface');
$objectNagios->printUsage ('Missing command line argument interface') unless (defined $interface);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Net::Ifconfig::Wrapper;

my $info = Net::Ifconfig::Wrapper::Ifconfig ( 'list', '', '', '' );

unless ( scalar( keys( %{$info} ) ) ) {
  $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'No one interface found. Something wrong?' }, $TYPE{APPEND} );
} else {
  if ( $info->{$interface}{status} ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{OK}, alert => "Interface '$interface': UP" }, $TYPE{APPEND} );
  } else {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "Interface '$interface': DOWN" }, $TYPE{APPEND} );
  }
}

$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
