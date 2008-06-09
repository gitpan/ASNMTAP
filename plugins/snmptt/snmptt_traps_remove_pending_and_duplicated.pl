#!/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2008 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2008/mm/dd, v3.000.017, snmptt_traps_remove_pending_and_duplicated.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.000.017;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'snmptt_traps_remove_pending_and_duplicated.pl',
  _programDescription => 'Remove Pending and Duplicated SNMPTT Traps from Database',
  _programVersion     => '3.000.017',
  _programUsagePrefix => '[-s|--server <hostname>] [--database=<database>]',
  _programHelpPrefix  => "-s, --server=<hostname> (default: localhost)
--database=<database> (default: snmptt)",
  _programGetOptions  => ['server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $serverDB = $objectNagios->getOptionsArgv ('server')   ? $objectNagios->getOptionsArgv ('server')   : 'localhost';
my $port     = $objectNagios->getOptionsArgv ('port')     ? $objectNagios->getOptionsArgv ('port')     : 3306;
my $database = $objectNagios->getOptionsArgv ('database') ? $objectNagios->getOptionsArgv ('database') : 'snmptt';
my $username = $objectNagios->getOptionsArgv ('username') ? $objectNagios->getOptionsArgv ('username') : 'asnmtap';
my $password = $objectNagios->getOptionsArgv ('password') ? $objectNagios->getOptionsArgv ('password') : '<PASSWORD>';

my $debug    = $objectNagios->getOptionsValue ('debug');
my $onDemand = $objectNagios->getOptionsValue ('onDemand');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode = $ERRORS{OK};
my $alert = 'OK:';

my ( $dbh, $sth, $prepareString );

$dbh = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbh ) {
  my $rv = 1;

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Cleanup LOGONLY and NAGIOS traps
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my $CATEGORY = '^(LOGONLY|NAGIOS)$';

  # Known Traps - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my $sqlINSERT = "INSERT INTO snmptt_archive SELECT * FROM snmptt WHERE category regexp '$CATEGORY'";
  print "    $sqlINSERT\n" if ( $debug );
  $dbh->do ( $sqlINSERT ) or $rv = _ErrorTrapDBI ( \$objectNagios,  'Cannot dbh->do: '. $sqlINSERT );

  if ( $rv ) {
    my $sqlDELETE = "DELETE snmptt FROM snmptt, snmptt_archive WHERE snmptt.id = snmptt_archive.id and snmptt.category regexp '$CATEGORY'";
    print "    $sqlDELETE\n" if ( $debug );
    $dbh->do( $sqlDELETE ) or $rv = _ErrorTrapDBI ( \$objectNagios,  'Cannot dbh->do: '. $sqlDELETE );
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Cleanup duplicated traps
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Known Traps - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $sqlINSERT = "INSERT INTO snmptt_archive SELECT * FROM snmptt WHERE EXISTS (
                     SELECT NULL
                     FROM snmptt b
                     WHERE b.eventname = snmptt.eventname
                       AND b.eventid = snmptt.eventid
                       AND b.trapoid = snmptt.trapoid
                       AND b.enterprise = snmptt.enterprise
                       AND b.community = snmptt.community
                       AND b.hostname = snmptt.hostname
                       AND b.agentip = snmptt.agentip
                       AND b.category = snmptt.category
                       AND b.severity = snmptt.severity
                       AND b.uptime = snmptt.uptime
                       AND b.formatline = snmptt.formatline
                       AND b.category regexp '$CATEGORY'
                     GROUP BY trapoid, enterprise, community, hostname, agentip, uptime, category, severity
                     HAVING snmptt.id < MAX(b.id)
                   )";

  print "    $sqlINSERT\n" if ( $debug );
  $dbh->do ( $sqlINSERT ) or $rv = _ErrorTrapDBI ( \$objectNagios,  'Cannot dbh->do: '. $sqlINSERT );

  if ( $rv ) {
    my $sqlDELETE = "DELETE snmptt FROM snmptt, snmptt_archive WHERE snmptt.id = snmptt_archive.id and snmptt.category regexp '$CATEGORY'";
    print "    $sqlDELETE\n" if ( $debug );
    $dbh->do( $sqlDELETE ) or $rv = _ErrorTrapDBI ( \$objectNagios,  'Cannot dbh->do: '. $sqlDELETE );
  }

  # Unknown Traps - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $sqlINSERT = "INSERT INTO snmptt_unknown_archive SELECT * FROM snmptt_unknown WHERE EXISTS (
                  SELECT NULL
                  FROM snmptt_unknown b
                  WHERE b.trapoid = snmptt_unknown.trapoid
                    AND b.enterprise = snmptt_unknown.enterprise
                    AND b.community = snmptt_unknown.community
                    AND b.hostname = snmptt_unknown.hostname
                    AND b.agentip = snmptt_unknown.agentip
                    AND b.uptime = snmptt_unknown.uptime
                    AND b.formatline = snmptt_unknown.formatline
                  GROUP BY trapoid, enterprise, community, hostname, agentip, uptime
                  HAVING snmptt_unknown.id < MAX(b.id)
                )";

  print "    $sqlINSERT\n" if ( $debug );
  $dbh->do ( $sqlINSERT ) or $rv = _ErrorTrapDBI ( \$objectNagios,  'Cannot dbh->do: '. $sqlINSERT );

  if ( $rv ) {
    my $sqlDELETE = "DELETE snmptt_unknown FROM snmptt_unknown, snmptt_unknown_archive WHERE snmptt_unknown.id = snmptt_unknown_archive.id";
    print "    $sqlDELETE\n" if ( $debug );
    $dbh->do( $sqlDELETE ) or $rv = _ErrorTrapDBI ( \$objectNagios,  'Cannot dbh->do: '. $sqlDELETE );
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $dbh->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
}

$objectNagios->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );
$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
