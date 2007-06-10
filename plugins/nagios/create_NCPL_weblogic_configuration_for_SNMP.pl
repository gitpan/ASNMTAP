#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/06/10, v3.000.014, create_NCPL_weblogic_configuration_for_SNMP.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Data::Dumper;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.000.014;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'create_NCPL_weblogic_configuration_for_SNMP.pl',
  _programDescription => 'Create NCPL weblogic configuration for SNMP',
  _programVersion     => '3.000.014',
  _programUsagePrefix => '[-s|--server=<hostname>] [--database=<database>] [--_server=<hostname>] [--_database=<database>] [--_port=<port>] [--_username=<username>] [--_password=<password>]',
  _programHelpPrefix  => "-s, --server=<hostname> (default: localhost)
--database=<database> (default: weblogicConfig)
--_server=<hostname> (default: localhost)
--_database=<database> (default: NCPL)
--_port=<port>
--_username=<username>
--_password=<password>",
  _programGetOptions  => ['_server:s', '_port:i', '_database:s', '_username|_loginname:s', '_password|_passwd:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $serverDB  = $objectPlugins->getOptionsArgv ('server')    ? $objectPlugins->getOptionsArgv ('server')    : 'localhost';
my $port      = $objectPlugins->getOptionsArgv ('port')      ? $objectPlugins->getOptionsArgv ('port')      : 3306;
my $database  = $objectPlugins->getOptionsArgv ('database')  ? $objectPlugins->getOptionsArgv ('database')  : 'weblogicConfig';
my $username  = $objectPlugins->getOptionsArgv ('username')  ? $objectPlugins->getOptionsArgv ('username')  : 'jUnit';
my $password  = $objectPlugins->getOptionsArgv ('password')  ? $objectPlugins->getOptionsArgv ('password')  : 'password';

my $_serverDB = $objectPlugins->getOptionsArgv ('_server')   ? $objectPlugins->getOptionsArgv ('_server')   : 'localhost';
my $_port     = $objectPlugins->getOptionsArgv ('_port')     ? $objectPlugins->getOptionsArgv ('_port')     : 3306;
my $_database = $objectPlugins->getOptionsArgv ('_database') ? $objectPlugins->getOptionsArgv ('_database') : 'ncpl';
my $_username = $objectPlugins->getOptionsArgv ('_username') ? $objectPlugins->getOptionsArgv ('_username') : 'ncpl';
my $_password = $objectPlugins->getOptionsArgv ('_password') ? $objectPlugins->getOptionsArgv ('_password') : 'password';

my $debug    = $objectPlugins->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode   = $ERRORS{OK};
my $alert        = 'OK';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $server_name         = 'snmpProbe01,snmpProbe02,distributedServer01,distributedServer02';
my $category            = '_SNMPTT_WEBLOGIC';
my $service_description = 'check snmp traps [wls -';
my $use                 = 'snmptt-service';
my $contact_groups      = 'middleware,supervision';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ( $dbhWEBLOGIC, $sthWEBLOGIC, $dbhNCPL, $sthNCPL, $prepareString );

$dbhWEBLOGIC = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
$dbhNCPL = DBI->connect ("DBI:mysql:$_database:$_serverDB:$_port", "$_username", "$_password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbhWEBLOGIC and $dbhNCPL ) {
  my $rv = 1;

  my $sqlDELETE = "DELETE FROM nagios_services WHERE category = '_SNMPTT_WEBLOGIC'";
  print "    $sqlDELETE\n" if ( $debug );
  $dbhNCPL->do( $sqlDELETE ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->do: '. $sqlDELETE ) if $rv;

  my ( $hostname, $domainname, $virtual_servername, $environment, $activated );

  my $sqlSTRING = "SELECT distinct ADMIN_CONFIG.HOST AS hostname, ADMIN_CONFIG.ADMIN_NAME AS domainname, SERVER_CONFIG.SERVER_NAME AS virtual_servername, ADMIN_CONFIG.ENV AS environment, ADMIN_CONFIG.activated FROM `ADMIN_CONFIG`, `SERVER_CONFIG`, `CLUSTER_CONFIG` WHERE ( SERVER_CONFIG.DOMAIN_NAME = concat('Domain\:', ADMIN_CONFIG.ADMIN_NAME) or SERVER_CONFIG.DOMAIN_NAME = concat('DOMAIN\:', ADMIN_CONFIG.ADMIN_NAME) ) AND ADMIN_CONFIG.ENV = SERVER_CONFIG.ENV AND SERVER_CONFIG.ENV = CLUSTER_CONFIG.ENV ORDER BY hostname, domainname, virtual_servername";
  print "    $sqlSTRING\n" if ( $debug );

  $sthWEBLOGIC = $dbhWEBLOGIC->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $sqlSTRING );
  $sthWEBLOGIC->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthWEBLOGIC->bind_columns( \$hostname, \$domainname, \$virtual_servername, \$environment, \$activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sthWEBLOGIC->fetch() ) {
      if ( $activated ) {
        my $sqlCOUNT = "SELECT count(host_name) FROM nagios_hosts WHERE host_name = '$hostname'";
        print "    $sqlCOUNT\n" if ( $debug );
        $sthNCPL = $dbhNCPL->prepare($sqlCOUNT) or _ErrorTrapDBI ( 'dbh->prepare '. $sqlCOUNT, "$DBI::err ($DBI::errstr)" );
        $sthNCPL->execute or _ErrorTrapDBI ( 'sth->execute '. $sqlCOUNT, "$DBI::err ($DBI::errstr)" );

        if ( $sthNCPL->fetchrow_array() ) {
          $sthNCPL->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $sqlCOUNT );
          my $sqlINSERT = "INSERT INTO nagios_services SET server_name = '$server_name', category = '$category', host_name = '$hostname', service_description = '$service_description $virtual_servername]', `use` = '$use', contact_groups = '$contact_groups', register = 1, enabled = $activated";
          print "    $sqlINSERT\n" if ( $debug );
          $dbhNCPL->do( $sqlINSERT ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->do: '. $sqlINSERT ) if $rv;
        } else {
          $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "$hostname doesn't EXIST" }, $TYPE{APPEND} );
        }
      }
    }

    $sthWEBLOGIC->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $sqlSTRING );
  }
}

$dbhWEBLOGIC->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhWEBLOGIC );
$dbhNCPL->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhNCPL );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
$objectPlugins->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );
$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

