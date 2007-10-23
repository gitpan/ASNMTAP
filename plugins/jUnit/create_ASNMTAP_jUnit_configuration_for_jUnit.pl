#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2007 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2007/10/21, v3.000.015, create_ASNMTAP_jUnit_configuration_for_jUnit.pl
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

use ASNMTAP::Time v3.000.015;
use ASNMTAP::Time qw(&get_datetimeSignal);

use ASNMTAP::Asnmtap::Applications v3.000.015;
use ASNMTAP::Asnmtap::Applications qw(&sending_mail $SERVERLISTSMTP $SENDMAILFROM);

use ASNMTAP::Asnmtap::Plugins v3.000.015;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS $SENDEMAILTO);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'create_ASNMTAP_jUnit_configuration_for_jUnit.pl',
  _programDescription => 'Create ASNMTAP jUnit configuration for jUnit',
  _programVersion     => '3.000.015',
  _programUsagePrefix => '[--update] [-s|--server=<hostname>] [--database=<database>] [--_server=<hostname>] [--_database=<database>] [--_port=<port>] [--_username=<username>] [--_password=<password>]',
  _programHelpPrefix  => "--update
-s, --server=<hostname> (default: localhost)
--database=<database> (default: weblogicConfig)
--_server=<hostname> (default: localhost)
--_database=<database> (default: asnmtap)
--_port=<port>
--_username=<username>
--_password=<password>",
  _programGetOptions  => ['update', 'hostname', 'domain:s', '_server:s', '_port:i', '_database:s', '_username|_loginname:s', '_password|_passwd:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $update     = $objectPlugins->getOptionsArgv ('update')    ? $objectPlugins->getOptionsArgv ('update')    : undef;

my $serverDB   = $objectPlugins->getOptionsArgv ('server')    ? $objectPlugins->getOptionsArgv ('server')    : 'localhost';
my $port       = $objectPlugins->getOptionsArgv ('port')      ? $objectPlugins->getOptionsArgv ('port')      : 3306;
my $database   = $objectPlugins->getOptionsArgv ('database')  ? $objectPlugins->getOptionsArgv ('database')  : 'jUnitConfig';
my $username   = $objectPlugins->getOptionsArgv ('username')  ? $objectPlugins->getOptionsArgv ('username')  : 'jUnit';
my $password   = $objectPlugins->getOptionsArgv ('password')  ? $objectPlugins->getOptionsArgv ('password')  : '<PASSWORD>';

my $_serverDB  = $objectPlugins->getOptionsArgv ('_server')   ? $objectPlugins->getOptionsArgv ('_server')   : 'localhost';
my $_port      = $objectPlugins->getOptionsArgv ('_port')     ? $objectPlugins->getOptionsArgv ('_port')     : 3306;
my $_database  = $objectPlugins->getOptionsArgv ('_database') ? $objectPlugins->getOptionsArgv ('_database') : 'asnmtap';
my $_username  = $objectPlugins->getOptionsArgv ('_username') ? $objectPlugins->getOptionsArgv ('_username') : 'asnmtap';
my $_password  = $objectPlugins->getOptionsArgv ('_password') ? $objectPlugins->getOptionsArgv ('_password') : '<PASSWORD>';

my $debug      = $objectPlugins->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode = $ERRORS{OK};
my $alert      = 'OK';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# plugins: dynamically
my $pluginTitle              = 'jUnit - ';
my $pluginHelpPluginFilename = '<NIHIL>';

# plugins: statically
my $pluginTest               = 'check_jUnit.pl';
my $pluginDatabaseArguments  = "--server=$_serverDB --port=$_port --database=jUnit --username=$_username --passwd=$_password";
my $pluginOndemand           = 1;
my $pluginProduction         = 1;
my $pluginPagedir            = '/index/';               # pagedirs: 'index' must exist
my $pluginResultsdir         = 'jUnit';                 # resultsdir: 'jUnit' must exist

# plugins: template
my $pluginTemplate = "ondemand='$pluginOndemand', production='$pluginProduction', pagedir='$pluginPagedir', resultsdir='$pluginResultsdir', helpPluginFilename = '$pluginHelpPluginFilename'";

# displayDaemons: dynamically
my $displayDaemon            = 'Supervisie';            # displayDaemon: 'Supervisie' must exist

# displayGroups: dynamically
my $displayGroupID           = '63';                    # displayGroupID: '63' must exist, displayGroupName: '73 CITAP (jUnit)'

# collectorDaemons: dynamically
my %collectorDaemon;
$collectorDaemon{PROD}       = 'jUnit-01';             # collectorDaemon: 'jUnit-01' must exist
$collectorDaemon{ACC}        = 'jUnit-01-ACC';          # collectorDaemon: 'jUnit-01-ACC' must exist
$collectorDaemon{SIM}        = $collectorDaemon{PROD};

# crontabs: statically
my $arguments                = '';
my $noOffline                = '';

# admin console: statically
my $adminConsoleHTTP         = 'http://';
my $adminConsoleDomainURL    = $domain;
my $adminConsoleApplication  = '/console/';
my $adminConsolePortOffset   = -100;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ( $dbhWEBLOGIC, $sthWEBLOGIC, $dbhASNMTAP, $sthASNMTAP, $prepareString, $actions );

$dbhWEBLOGIC = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
$dbhASNMTAP = DBI->connect ("DBI:mysql:$_database:$_serverDB:$_port", "$_username", "$_password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbhWEBLOGIC and $dbhASNMTAP ) {
  my %ENVIRONMENT = ('PROD'=>'Production', 'SIM'=>'Simulation', 'ACC'=>'Acceptation');

  my ($rv, $sqlSTRING, $adminName, $host, $port, $community, $version, $environment, $activated, $uKey, $holidayBundleID, $step, $minute, $hour, $dayOfTheMonth, $monthOfTheYear, $dayOfTheWeek, $adminConsoleCheck ) = (1);
  $sqlSTRING = 'SELECT ADMIN_NAME, HOST, PORT, COMMUNITY, VERSION, ENV, ACTIVATED, uKey, holidayBundleID, step, minute, hour, dayOfTheMonth, monthOfTheYear, dayOfTheWeek, adminConsoleCheck FROM `ADMIN_CONFIG`';

  $actions .= "WEBLOGIC: $sqlSTRING\n" if ( $debug );
  $sthWEBLOGIC = $dbhWEBLOGIC->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $sqlSTRING );
  $sthWEBLOGIC->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthWEBLOGIC->bind_columns( \$adminName, \$host, \$port, \$community, \$version, \$environment, \$activated, \$uKey, \$holidayBundleID, \$step, \$minute, \$hour, \$dayOfTheMonth, \$monthOfTheYear, \$dayOfTheWeek, \$adminConsoleCheck ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sthWEBLOGIC->fetch() ) {
      my $_Environment = substr($environment, 0, 1);
      $actions .= "\n+ $adminName, $host, $port, $community, $version, $environment, $activated, $uKey, $holidayBundleID\n" if ( $debug );

      # plugins
      my ($_uKey, $_title, $_environment, $_step, $_helpPluginFilename, $_holidayBundleID, $_activated);
      $sqlSTRING = "SELECT uKey, title, environment, step, helpPluginFilename, holidayBundleID, activated FROM `plugins` WHERE uKey='$uKey' order by uKey";
      $actions .= "  ASNMTAP: $sqlSTRING\n" if ( $debug );
      $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $sqlSTRING );
      $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
      $sthASNMTAP->bind_columns( \$_uKey, \$_title, \$_environment, \$_step, \$_helpPluginFilename, \$_holidayBundleID, \$_activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        my $adminConsole = $adminConsoleCheck ? '--adminConsole=' . $adminConsoleHTTP . $host .'.'. $adminConsoleDomainURL .':'. ( $port + $adminConsolePortOffset ) . $adminConsoleApplication : '' ;

        if ( $sthASNMTAP->fetch() ) {
          my $sqlUPDATE = ( defined $update ? 1 : 0 );
          $actions .= "  + $_uKey, $_title, $_environment, $_step, $_helpPluginFilename, $_holidayBundleID, $_activated\n" if ( $debug );

          if ( "Weblogic - $adminName" ne $_title ) {
            $sqlUPDATE++;
            $actions .= "  - title changed to 'Weblogic - $adminName'\n" if ( $debug );
          }

          if ( $_Environment ne $_environment ) {
            $sqlUPDATE++;
            $actions .= "  - environment changed to '". $ENVIRONMENT{$environment} ."'\n" if ( $debug );
          }

          if ( $step != $_step ) {
            $sqlUPDATE++;
            $actions .= "  - step changed to '$step' \n" if ( $debug );
          }

          if ( $pluginHelpPluginFilename ne $_helpPluginFilename ) {
            $sqlUPDATE++;
            $actions .= "  - helpPluginFilename changed to '$pluginHelpPluginFilename'\n" if ( $debug );
          }

          if ( $holidayBundleID ne $_holidayBundleID ) {
            $sqlUPDATE++;
            $actions .= "  - holidayBundleID changed to '$holidayBundleID'\n" if ( $debug );
          }

          if ( $activated ne $_activated ) {
            $sqlUPDATE++;
            $actions .= "  - plugin ". ($activated ? '' : 'de') ."activated\n" if ( $debug );
          }

          if ( $sqlUPDATE ) {
            $sqlUPDATE = "UPDATE `plugins` SET title='$pluginTitle$adminName', arguments='$pluginDatabaseArguments --uKey=$uKey --community=$community". ( defined $hostname ? " --host=$host" : '' ) ." $adminConsole', environment='$_Environment', test='$pluginTest', $pluginTemplate, holidayBundleID='$holidayBundleID', step='$step', activated='$activated' WHERE uKey='$uKey'";
            $actions .= "  ASNMTAP: $sqlUPDATE\n";
            $dbhASNMTAP->do( $sqlUPDATE ) or $rv = errorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE");
          }
        } else {
          $actions .= "  ASNMTAP: ukey '$uKey' doesn't exist\n";
          my $sqlINSERT = "INSERT INTO `plugins` SET uKey='$uKey', title='$pluginTitle$adminName', arguments='$pluginDatabaseArguments --uKey=$uKey --community=$community". ( defined $hostname ? " --host=$host" : '' ) ." $adminConsole', environment='$_Environment', test='$pluginTest', $pluginTemplate, holidayBundleID='$holidayBundleID', step='$step', activated='$activated'";
          $actions .= "  ASNMTAP: $sqlINSERT\n";
          $dbhASNMTAP->do( $sqlINSERT ) or $rv = errorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT");
        }

        $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $sqlSTRING );
      }

      # views
      my ($_displayDaemon, $_displayGroupID);
      $sqlSTRING = "SELECT uKey, displayDaemon, displayGroupID, activated FROM `views` WHERE uKey='$uKey' order by uKey";
      $actions .= "  ASNMTAP: $sqlSTRING\n" if ( $debug );
      $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $sqlSTRING );
      $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
      $sthASNMTAP->bind_columns( \$_uKey, \$_displayDaemon, \$_displayGroupID, \$_activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        if ( $sthASNMTAP->fetch() ) {
          my $sqlUPDATE = ( defined $update ? 1 : 0 );
          $actions .= "  + $_uKey, $_displayDaemon, $_displayGroupID, $_activated\n" if ( $debug );

          if ( $displayDaemon ne $_displayDaemon ) {
            $sqlUPDATE++;
            $actions .= "  - displayDaemon changed to '$displayDaemon'\n" if ( $debug );
          }

          if ( $displayGroupID ne $_displayGroupID ) {
            $sqlUPDATE++;
            $actions .= "  - displayGroupID changed to '$displayGroupID'\n" if ( $debug );
          }

          if ( $activated ne $_activated ) {
            $sqlUPDATE++;
            $actions .= "  - view ". ($activated ? '' : 'de') ."activated\n" if ( $debug );
          }

          if ( $sqlUPDATE ) {
            $sqlUPDATE = "UPDATE `views` SET displayDaemon='$displayDaemon', displayGroupID='$displayGroupID', activated='$activated' WHERE uKey='$uKey'";
            $actions .= "  ASNMTAP: $sqlUPDATE\n";
            $dbhASNMTAP->do( $sqlUPDATE ) or $rv = errorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE");
          }
        } else {
          $actions .= "  ASNMTAP: ukey '$uKey' doesn't exist\n";
          my $sqlINSERT = "INSERT INTO `views` SET uKey='$uKey', displayDaemon='$displayDaemon', displayGroupID='$displayGroupID', activated='$activated'";
          $actions .= "  ASNMTAP: $sqlINSERT\n";
          $dbhASNMTAP->do( $sqlINSERT ) or $rv = errorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT");
        }

        $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $sqlSTRING );
      }

      # crontabs
      my ($_lineNumber, $_collectorDaemon, $_arguments, $_minute, $_hour, $_dayOfTheMonth, $_monthOfTheYear, $_dayOfTheWeek, $_noOffline);
      $sqlSTRING = "SELECT uKey, lineNumber, collectorDaemon, arguments, minute, hour, dayOfTheMonth, monthOfTheYear, dayOfTheWeek, noOffline, activated FROM `crontabs` WHERE uKey='$uKey' and lineNumber='00' order by uKey";
      $actions .= "  ASNMTAP: $sqlSTRING\n" if ( $debug );
      $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $sqlSTRING );
      $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
      $sthASNMTAP->bind_columns( \$_uKey, \$_lineNumber, \$_collectorDaemon, \$_arguments, \$_minute, \$_hour, \$_dayOfTheMonth, \$_monthOfTheYear, \$_dayOfTheWeek, \$_noOffline, \$_activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        if ( $sthASNMTAP->fetch() ) {
          my $sqlUPDATE = ( defined $update ? 1 : 0 );
          $actions .= "  + $_uKey, $_lineNumber, $_collectorDaemon, $_arguments, $_minute, $_hour, $_dayOfTheMonth, $_monthOfTheYear, $_dayOfTheWeek, $_noOffline, $_activated\n" if ( $debug );

          if ( $collectorDaemon{$environment} ne $_collectorDaemon ) {
            $sqlUPDATE++;
            $actions .= "  - collectorDaemon changed to '". $collectorDaemon{$environment} ."'\n" if ( $debug );
          }

          if ( $minute ne $_minute ) {
            $sqlUPDATE++;
            $actions .= "  - minute changed to '$minute'\n" if ( $debug );
          }

          if ( $hour ne $_hour ) {
            $sqlUPDATE++;
            $actions .= "  - hour changed to '$hour'\n" if ( $debug );
          }

          if ( $dayOfTheWeek ne $_dayOfTheWeek ) {
            $sqlUPDATE++;
            $actions .= "  - dayOfTheWeek changed to '$dayOfTheWeek'\n" if ( $debug );
          }

          if ( $activated ne $_activated ) {
            $sqlUPDATE++;
            $actions .= "  - crontab ". ($activated ? '' : 'de') ."activated\n" if ( $debug );
          }

          if ( $sqlUPDATE ) {
            $sqlUPDATE = "UPDATE `crontabs` SET collectorDaemon='". $collectorDaemon{$environment} ."', arguments='$arguments', minute='$minute', hour='$hour', dayOfTheMonth='$dayOfTheMonth', monthOfTheYear='$monthOfTheYear', dayOfTheWeek='$dayOfTheWeek', noOffline='$noOffline', activated='$activated' WHERE uKey='$uKey' and lineNumber='00'";
            $actions .= "  ASNMTAP: $sqlUPDATE\n";
            $dbhASNMTAP->do( $sqlUPDATE ) or $rv = errorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE");
          }
        } else {
          $actions .= "  ASNMTAP: ukey '$uKey' doesn't exist\n";
          my $sqlINSERT = "INSERT INTO `crontabs` SET uKey='$uKey', lineNumber='00', collectorDaemon='". $collectorDaemon{$environment} ."', arguments='$arguments', minute='$minute', hour='$hour', dayOfTheMonth='$dayOfTheMonth', monthOfTheYear='$monthOfTheYear', dayOfTheWeek='$dayOfTheWeek', noOffline='$noOffline', activated='$activated'";
          $actions .= "  ASNMTAP: $sqlINSERT\n";
          $dbhASNMTAP->do( $sqlINSERT ) or $rv = errorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT");
        }

        $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $sqlSTRING );
      }
    }

    $sthWEBLOGIC->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $sqlSTRING );
  }
}

$dbhASNMTAP->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhASNMTAP );
$dbhWEBLOGIC->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhWEBLOGIC );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );

if ( defined $actions ) {
  unless ( sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, 'ASNMTAP ~ Weblogic: '. get_datetimeSignal(), $actions, $debug ) ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Problem sending email to the System Administrators" }, $TYPE{APPEND} );
  }
}

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
