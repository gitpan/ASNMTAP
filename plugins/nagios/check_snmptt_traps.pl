#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/09/16, v3.000.011, check_snmptt_traps.pl drop-in replacement for NagTrap
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.000.011;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_snmptt_traps.pl',
  _programDescription => 'Nagios SNMPTT Traps Database',
  _programVersion     => '3.000.011',
  _programUsagePrefix => '[-H|--hostname <hostname>] [-O|--trapOID <trapoid>] [--database=<database>]',
  _programHelpPrefix  => "-H, --hostname=<Nagios Hostname>
-O, --trapOID=<SNMP trapoid>
--database=<database> (default: odbc)",
  _programGetOptions  => ['hostname|H:s', 'trapOID|O:s', 'host|H:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|passwd|p:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $hostname = $objectNagios->getOptionsArgv ('hostname') ? $objectNagios->getOptionsArgv ('hostname') : undef;
$objectNagios->printUsage ('Missing command line argument hostname') unless (defined $hostname);

my $trapOID  = $objectNagios->getOptionsArgv ('trapOID')  ? $objectNagios->getOptionsArgv ('trapOID')  : undef;

my $serverDB = $objectNagios->getOptionsArgv ('host')     ? $objectNagios->getOptionsArgv ('host')     : 'localhost';
my $port     = $objectNagios->getOptionsArgv ('port')     ? $objectNagios->getOptionsArgv ('port')     : 3306;
my $database = $objectNagios->getOptionsArgv ('database') ? $objectNagios->getOptionsArgv ('database') : 'odbc';
my $username = $objectNagios->getOptionsArgv ('username') ? $objectNagios->getOptionsArgv ('username') : 'asnmtap';
my $password = $objectNagios->getOptionsArgv ('password') ? $objectNagios->getOptionsArgv ('password') : 'asnmtap';

my $environment = $objectNagios->getOptionsArgv ('environment');

my $debug = $objectNagios->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode = $ERRORS{UNKNOWN};
my $alert = 'UNKNOWN:';

my ( $dbh, $sth, $prepareString );

$dbh = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or errorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbh ) {
  my $trapOIDString = (defined $trapOID) ? "and trapoid = '$trapOID'" : '';

  $prepareString = "select count(*) from snmptt where hostname = '$hostname' $trapOIDString";
  $sth = $dbh->prepare($prepareString) or errorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
  $sth->execute or errorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );
  my $count = $sth->fetchrow_array();
  $sth->finish() or errorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );

  $prepareString = "select count(*) from snmptt where hostname = '$hostname' and severity = 'CRITICAL' and trapread = '0'  $trapOIDString";
  $sth = $dbh->prepare($prepareString) or errorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
  $sth->execute or errorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );
  my $countCRITICAL = $sth->fetchrow_array();
  $sth->finish() or errorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );

  if ( $countCRITICAL > 0 ) {
    $alert = "CRITICAL: $countCRITICAL Critical Traps for $hostname. $count Traps in Database";
    $returnCode = $ERRORS{CRITICAL};
  } else {
    $prepareString = "select count(*) from snmptt where hostname = '$hostname' and severity = 'WARNING' and trapread = '0' $trapOIDString";
    $sth = $dbh->prepare($prepareString) or errorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
    $sth->execute or errorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );
    my $countWARNING = $sth->fetchrow_array();
    $sth->finish() or errorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );

    if ( $countWARNING > 0 ) {
      $alert = "WARNING: $countWARNING Warning Traps for $hostname. $count Traps in Database";
      $returnCode = $ERRORS{WARNING};
    } else {
      $alert = "OK: No Warning or Critical Traps for $hostname. $count Traps in Database";
      $returnCode = $ERRORS{OK};
    }
  }

  $dbh->disconnect or errorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
}

$objectNagios->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );
$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($error, $errorDBI) = @_;

  $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "$error - $errorDBI" }, $TYPE{APPEND} );
  $objectNagios->exit (7);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
