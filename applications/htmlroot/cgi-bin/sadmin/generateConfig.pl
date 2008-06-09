#!/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2008 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2008/mm/dd, v3.000.017, generateConfig.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;
use File::stat;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.000.017;
use ASNMTAP::Time qw(&get_csvfiledate &get_csvfiletime);

use ASNMTAP::Asnmtap::Applications::CGI v3.000.017;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :SADMIN :DBREADWRITE :DBTABLES $DIFFCOMMAND $RSYNCCOMMAND);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "generateConfig.pl";
my $prgtext     = "Generate Config";
my $version     = do { my @r = (q$Revision: 3.000.017$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : 'sadmin';  $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : 'F';
my $action  = (defined $cgi->param('action'))  ? $cgi->param('action')  : 'menuView';

my ($Cplugin, $ChelpPluginFilename, $Ctodo);

if ($action eq 'updateView' or $action eq 'update') {
  $Cplugin             = (defined $cgi->param('plugin'))             ? $cgi->param('plugin')             : '';
  $ChelpPluginFilename = (defined $cgi->param('helpPluginFilename')) ? $cgi->param('helpPluginFilename') : '';
  $Ctodo               = (defined $cgi->param('todo'))               ? $cgi->param('todo')               : '';
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $numberCentralServers, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);
my (@matchingAsnmtapCollectorCTscript, @matchingAsnmtapDisplayCTscript);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Generate Config", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&action=$action";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>action            : $action<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?debug=$debug&amp;CGISESSID=$sessionID";

  my ($compareView, $installView, $initializeGenerateView, $matchingWarnings, $countWarnings, $matchingErrors, $countErrors, $matchingArchiveCT, $matchingCollectorCT, $matchingAsnmtapCollectorCTscript, $matchingDisplayCT, $matchingAsnmtapDisplayCTscript, $matchingRsyncMirror);
  $compareView = $installView = $initializeGenerateView = $matchingWarnings = $matchingErrors = $matchingArchiveCT = $matchingCollectorCT = $matchingAsnmtapCollectorCTscript = $matchingDisplayCT = $matchingAsnmtapDisplayCTscript = $matchingRsyncMirror = '';
  $countWarnings = $countErrors = 0;

  if ($action eq 'checkView') {
    $htmlTitle = "Check Configuration";
  } elsif ($action eq 'generateView') {
    $htmlTitle = "Generate Configuration";
  } elsif ($action eq 'compareView') {
    $htmlTitle = "Compare Configurations";
  } elsif ($action eq 'installView') {
    $htmlTitle = "Install Configuration";
  } elsif ($action eq 'install') {
    $htmlTitle = "Configuration Installed";
  } elsif ($action eq 'updateView') {
    $htmlTitle = "Update Configuration";
  } elsif ($action eq 'update') {
    $htmlTitle = "Configuration Updated";
  } else {
    $action    = "menuView";
    $htmlTitle = "Configuration Menu";
  }

  $rv  = 1;

  if ($action eq 'checkView' or $action eq 'generateView') {
    # open connection to database and query data
    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

    if ($dbh and $rv) {
      my ($serverID, $displayDaemon, $collectorDaemon, $resultsdir, $groupTitle, $pagedirs, $uKey, $test, $interval, $title, $helpPluginFilename, $environment, $trendline, $minute, $hour, $dayOfTheMonth, $monthOfTheYear, $dayOfTheWeek, $argumentsCommon, $argumentsCrontab, $noOffline);
      my ($prevServerID, $prevTypeServers, $prevTypeMonitoring, $prevMasterFQDN, $prevSlaveFQDN, $prevDisplayDaemon, $prevCollectorDaemon, $prevResultsdir, $prevGroupTitle, $prevPagedir, $prevUniqueKey);
      my ($centralServerID, $centralTypeMonitoring, $centralTypeServers, $centralMasterFQDN, $centralMasterDatabaseFQDN, $centralSlaveFQDN, $centralSlaveDatabaseFQDN);

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      my ($warning, $error, $count, $sqlTmp, $sthTmp, $actionItem);

      $matchingWarnings .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th colspan=\"3\">Warnings:</th></tr>";
      $matchingErrors .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th colspan=\"3\">Errors:</th></tr>";

      # displayDaemons <-> views  - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Display Daemons <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Display Daemon</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLDISPLAYDMNS.displayDaemon, count($SERVERTABLVIEWS.displayDaemon) FROM $SERVERTABLDISPLAYDMNS LEFT JOIN $SERVERTABLVIEWS ON $SERVERTABLDISPLAYDMNS.displayDaemon = $SERVERTABLVIEWS.displayDaemon where $SERVERTABLDISPLAYDMNS.activated = 1 group by $SERVERTABLDISPLAYDMNS.displayDaemon";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLDISPLAYDMNS but is not used into $SERVERTABLVIEWS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Display Daemons <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Display Daemon</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLVIEWS.displayDaemon, count($SERVERTABLDISPLAYDMNS.displayDaemon) FROM $SERVERTABLVIEWS LEFT JOIN $SERVERTABLDISPLAYDMNS ON $SERVERTABLVIEWS.displayDaemon = $SERVERTABLDISPLAYDMNS.displayDaemon where $SERVERTABLVIEWS.activated = 1 group by $SERVERTABLVIEWS.displayDaemon";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLVIEWS but don't exist anymore into $SERVERTABLDISPLAYDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # displayGroups <-> views - - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Display Daemons <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Display Group</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLDISPLAYGRPS.groupTitle, count($SERVERTABLVIEWS.displayGroupID) FROM $SERVERTABLDISPLAYGRPS LEFT JOIN $SERVERTABLVIEWS ON $SERVERTABLDISPLAYGRPS.displayGroupID = $SERVERTABLVIEWS.displayGroupID where $SERVERTABLDISPLAYGRPS.activated = 1 group by $SERVERTABLDISPLAYGRPS.displayGroupID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLDISPLAYGRPS but is not used into $SERVERTABLVIEWS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Display Daemons <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Display Group</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLVIEWS.displayGroupID, count($SERVERTABLDISPLAYGRPS.displayGroupID) FROM $SERVERTABLVIEWS LEFT JOIN $SERVERTABLDISPLAYGRPS ON $SERVERTABLVIEWS.displayGroupID = $SERVERTABLDISPLAYGRPS.displayGroupID where $SERVERTABLVIEWS.activated = 1 group by $SERVERTABLVIEWS.displayGroupID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLVIEWS but don't exist anymore into $SERVERTABLDISPLAYGRPS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # collectorDaemons <-> crontabs - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Collector Daemons <-> Crontabs</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Collector Daemon</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLCLLCTRDMNS.collectorDaemon, count($SERVERTABLCRONTABS.collectorDaemon) FROM $SERVERTABLCLLCTRDMNS LEFT JOIN $SERVERTABLCRONTABS ON $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon where $SERVERTABLCLLCTRDMNS.activated = 1 group by $SERVERTABLCLLCTRDMNS.collectorDaemon";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLCLLCTRDMNS but is not used into $SERVERTABLCRONTABS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Collector Daemons <-> Crontabs</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Collector Daemon</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLCRONTABS.collectorDaemon, count($SERVERTABLCLLCTRDMNS.collectorDaemon) FROM $SERVERTABLCRONTABS LEFT JOIN $SERVERTABLCLLCTRDMNS ON $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon where $SERVERTABLCRONTABS.activated = 1 group by $SERVERTABLCRONTABS.collectorDaemon";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLCRONTABS but don't exist anymore into $SERVERTABLCLLCTRDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # pagedirs <-> displayDaemons - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Display Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLPAGEDIRS.pagedir, count($SERVERTABLDISPLAYDMNS.pagedir) FROM $SERVERTABLPAGEDIRS LEFT JOIN $SERVERTABLDISPLAYDMNS ON $SERVERTABLPAGEDIRS.pagedir = $SERVERTABLDISPLAYDMNS.pagedir where $SERVERTABLPAGEDIRS.activated = 1 group by $SERVERTABLPAGEDIRS.pagedir";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPAGEDIRS but is not used into $SERVERTABLDISPLAYDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Display Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLDISPLAYDMNS.pagedir, count($SERVERTABLPAGEDIRS.pagedir) FROM $SERVERTABLDISPLAYDMNS LEFT JOIN $SERVERTABLPAGEDIRS ON $SERVERTABLDISPLAYDMNS.pagedir = $SERVERTABLPAGEDIRS.pagedir where $SERVERTABLDISPLAYDMNS.activated = 1 group by $SERVERTABLDISPLAYDMNS.pagedir";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLDISPLAYDMNS but don't exist anymore into $SERVERTABLPAGEDIRS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # pagedirs <-> plugins  - - - - - - - - - - - - - - - - - - - - - -
      $sqlTmp = "drop temporary table if exists tmp$SERVERTABLPLUGINS";
      $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

        $sqlTmp = "create temporary table `tmp$SERVERTABLPLUGINS`(`pagedir` varchar(11) default '') TYPE=InnoDB";
        $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

        if ( $rv ) {
          $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

          $sql = "SELECT $SERVERTABLPLUGINS.pagedir FROM $SERVERTABLPLUGINS";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
          $sth->bind_columns( \$pagedirs ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

          if ( $rv ) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                chop ($pagedirs);
                $pagedirs = substr($pagedirs, 1);
                my @pagedirs = split (/\//, $pagedirs);

                foreach my $pagedirTmp (@pagedirs) {
                  $sqlTmp = "insert into tmp$SERVERTABLPLUGINS set pagedir = '$pagedirTmp'";
                  $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
                  $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
                  $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          }

          $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Plugins</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
          $sql = "SELECT $SERVERTABLPAGEDIRS.pagedir, count(tmp$SERVERTABLPLUGINS.pagedir) FROM $SERVERTABLPAGEDIRS LEFT JOIN tmp$SERVERTABLPLUGINS ON $SERVERTABLPAGEDIRS.pagedir = tmp$SERVERTABLPLUGINS.pagedir where $SERVERTABLPAGEDIRS.activated = 1 group by $SERVERTABLPAGEDIRS.pagedir";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
          $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

          if ($rv) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                if ($count == 0) {
                  $countWarnings++;
                  $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPAGEDIRS but is not used into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          }

          $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Plugins</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
          $sql = "SELECT tmp$SERVERTABLPLUGINS.pagedir, count($SERVERTABLPAGEDIRS.pagedir) FROM tmp$SERVERTABLPLUGINS LEFT JOIN $SERVERTABLPAGEDIRS ON tmp$SERVERTABLPLUGINS.pagedir = $SERVERTABLPAGEDIRS.pagedir where $SERVERTABLPAGEDIRS.activated = 1 group by tmp$SERVERTABLPLUGINS.pagedir";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
          $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

          if ($rv) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                if ($count == 0) {
                  $countErrors++;
                  $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLPLUGINS but don't exist anymore into $SERVERTABLPAGEDIRS</td><td>&nbsp;</td></tr>";
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          }
	
          $sqlTmp = "drop temporary table tmp$SERVERTABLPLUGINS";
          $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
          $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        }
      }

      # pagedirs <-> users  - - - - - - - - - - - - - - - - - - - - - - -
      $sqlTmp = "drop temporary table if exists tmp$SERVERTABLUSERS";
      $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

        $sqlTmp = "create temporary table `tmp$SERVERTABLUSERS`(`pagedir` varchar(11) default '') TYPE=InnoDB";
        $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

        if ( $rv ) {
          $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

          $sql = "SELECT $SERVERTABLUSERS.pagedir FROM $SERVERTABLUSERS";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
          $sth->bind_columns( \$pagedirs ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

          if ( $rv ) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                chop ($pagedirs);
                $pagedirs = substr($pagedirs, 1);
                my @pagedirs = split (/\//, $pagedirs);

                foreach my $pagedirTmp (@pagedirs) {
                  $sqlTmp = "insert into tmp$SERVERTABLUSERS set pagedir = '$pagedirTmp'";
                  $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
                  $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
                  $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          }

          $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Users</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
          $sql = "SELECT $SERVERTABLPAGEDIRS.pagedir, count(tmp$SERVERTABLUSERS.pagedir) FROM $SERVERTABLPAGEDIRS LEFT JOIN tmp$SERVERTABLUSERS ON $SERVERTABLPAGEDIRS.pagedir = tmp$SERVERTABLUSERS.pagedir where $SERVERTABLPAGEDIRS.activated = 1 group by $SERVERTABLPAGEDIRS.pagedir";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
          $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

          if ($rv) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                if ($count == 0) {
                  $countWarnings++;
                  $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPAGEDIRS but is not used into $SERVERTABLUSERS</td><td>&nbsp;</td></tr>";
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          }

          $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Users</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
          $sql = "SELECT tmp$SERVERTABLUSERS.pagedir, count($SERVERTABLPAGEDIRS.pagedir) FROM tmp$SERVERTABLUSERS LEFT JOIN $SERVERTABLPAGEDIRS ON tmp$SERVERTABLUSERS.pagedir = $SERVERTABLPAGEDIRS.pagedir where $SERVERTABLPAGEDIRS.activated = 1 group by tmp$SERVERTABLUSERS.pagedir";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
          $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

          if ($rv) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                if ($count == 0) {
                  $countErrors++;
                  $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLUSERS but don't exist anymore into $SERVERTABLPAGEDIRS</td><td>&nbsp;</td></tr>";
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          }

          $sqlTmp = "drop temporary table tmp$SERVERTABLUSERS";
          $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
          $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        }
      }

      # plugins <-> comments  - - - - - - - - - - - - - - - - - - - - - -
      # $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Comments</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      # $sql = "SELECT $SERVERTABLPLUGINS.uKey, count($SERVERTABLCOMMENTS.uKey) FROM $SERVERTABLPLUGINS LEFT JOIN $SERVERTABLCOMMENTS ON $SERVERTABLPLUGINS.uKey = $SERVERTABLCOMMENTS.uKey where $SERVERTABLPLUGINS.activated = 1 group by $SERVERTABLPLUGINS.uKey";
      # $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      # $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      # $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      # if ($rv) {
      #   if ( $sth->rows ) {
      #     while( $sth->fetch() ) {
      #     if ($count == 0) {
      #       $countWarnings++;
      #       $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPLUGINS but is not used into $SERVERTABLCOMMENTS</td><td>&nbsp;</td></tr>";
      #       }
      #     }
      #   }
      #
      #   $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      # }

      # $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Comments</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      # $sql = "SELECT $SERVERTABLCOMMENTS.uKey, count($SERVERTABLPLUGINS.uKey) FROM $SERVERTABLCOMMENTS LEFT JOIN $SERVERTABLPLUGINS ON $SERVERTABLCOMMENTS.uKey = $SERVERTABLPLUGINS.uKey where $SERVERTABLCOMMENTS.activated = 1 group by $SERVERTABLCOMMENTS.uKey";
      # $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      # $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      # $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      # if ($rv) {
      #   if ( $sth->rows ) {
      #     while( $sth->fetch() ) {
      #       if ($count == 0) {
      #         $countErrors++;
      #         $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLCOMMENTS but don't exist anymore into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
      #       }
      #     }
      #   }
      #
      #   $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      # }

      # plugins <-> crontabs  - - - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Crontabs</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLPLUGINS.uKey, count($SERVERTABLCRONTABS.uKey) FROM $SERVERTABLPLUGINS LEFT JOIN $SERVERTABLCRONTABS ON $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey where $SERVERTABLPLUGINS.activated = 1 group by $SERVERTABLPLUGINS.uKey";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPLUGINS but is not used into $SERVERTABLCRONTABS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Crontabs</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLCRONTABS.uKey, count($SERVERTABLPLUGINS.uKey) FROM $SERVERTABLCRONTABS LEFT JOIN $SERVERTABLPLUGINS ON $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey where $SERVERTABLCRONTABS.activated = 1 group by $SERVERTABLCRONTABS.uKey";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLCRONTABS but don't exist anymore into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # plugins <-> views - - - - - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLPLUGINS.uKey, count($SERVERTABLVIEWS.uKey) FROM $SERVERTABLPLUGINS LEFT JOIN $SERVERTABLVIEWS ON $SERVERTABLPLUGINS.uKey = $SERVERTABLVIEWS.uKey where $SERVERTABLPLUGINS.activated = 1 group by $SERVERTABLPLUGINS.uKey";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPLUGINS but is not used into $SERVERTABLVIEWS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLVIEWS.uKey, count($SERVERTABLPLUGINS.uKey) FROM $SERVERTABLVIEWS LEFT JOIN $SERVERTABLPLUGINS ON $SERVERTABLVIEWS.uKey = $SERVERTABLPLUGINS.uKey where $SERVERTABLVIEWS.activated = 1 group by $SERVERTABLVIEWS.uKey";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLVIEWS but don't exist anymore into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # resultsdir <-> plugins  - - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Resultsdir <-> Plugins</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Resultsdir</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLRESULTSDIR.resultsdir, count($SERVERTABLPLUGINS.resultsdir) FROM $SERVERTABLRESULTSDIR LEFT JOIN $SERVERTABLPLUGINS ON $SERVERTABLRESULTSDIR.resultsdir = $SERVERTABLPLUGINS.resultsdir where $SERVERTABLPLUGINS.activated = 1 group by $SERVERTABLRESULTSDIR.resultsdir";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLRESULTSDIR but is not used into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Resultsdir <-> Plugins</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Resultsdir</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLPLUGINS.resultsdir, count($SERVERTABLRESULTSDIR.resultsdir) FROM $SERVERTABLPLUGINS LEFT JOIN $SERVERTABLRESULTSDIR ON $SERVERTABLPLUGINS.resultsdir = $SERVERTABLRESULTSDIR.resultsdir where $SERVERTABLPLUGINS.activated = 1 group by $SERVERTABLPLUGINS.resultsdir";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLPLUGINS but don't exist anymore into $SERVERTABLRESULTSDIR</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # servers <-> collectorDaemons  - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Collector Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Server ID</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLSERVERS.serverID, count($SERVERTABLCLLCTRDMNS.serverID) FROM $SERVERTABLSERVERS LEFT JOIN $SERVERTABLCLLCTRDMNS ON $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID where $SERVERTABLSERVERS.activated = 1 group by $SERVERTABLSERVERS.serverID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLSERVERS but is not used into $SERVERTABLCLLCTRDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Collector Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Server ID</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLCLLCTRDMNS.serverID, count($SERVERTABLSERVERS.serverID) FROM $SERVERTABLCLLCTRDMNS LEFT JOIN $SERVERTABLSERVERS ON $SERVERTABLCLLCTRDMNS.serverID = $SERVERTABLSERVERS.serverID where $SERVERTABLCLLCTRDMNS.activated = 1 group by $SERVERTABLCLLCTRDMNS.serverID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLCLLCTRDMNS but don't exist anymore into $SERVERTABLSERVERS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # servers <-> displayDaemons  - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Display Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Server ID</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLSERVERS.serverID, count($SERVERTABLDISPLAYDMNS.serverID) FROM $SERVERTABLSERVERS LEFT JOIN $SERVERTABLDISPLAYDMNS ON $SERVERTABLSERVERS.serverID = $SERVERTABLDISPLAYDMNS.serverID where $SERVERTABLSERVERS.activated = 1 group by $SERVERTABLSERVERS.serverID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLSERVERS but is not used into $SERVERTABLDISPLAYDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Display Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Server ID</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLDISPLAYDMNS.serverID, count($SERVERTABLSERVERS.serverID) FROM $SERVERTABLDISPLAYDMNS LEFT JOIN $SERVERTABLSERVERS ON $SERVERTABLDISPLAYDMNS.serverID = $SERVERTABLSERVERS.serverID where $SERVERTABLDISPLAYDMNS.activated = 1 group by $SERVERTABLDISPLAYDMNS.serverID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLDISPLAYDMNS but don't exist anymore into $SERVERTABLSERVERS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # servers <-> servers - - - - - - - - - - - - - - - - - - - - - - -
      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Servers</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Central Monitoring Servers</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT count(typeMonitoring) FROM $SERVERTABLSERVERS where typeMonitoring = 0 and activated = 1 group by typeMonitoring";
      ($rv, $numberCentralServers) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      unless ( defined $numberCentralServers) {
        $countErrors++;
        $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>0</td><td>there is no activated central monitoring server</td><td>&nbsp;</td></tr>";
      } elsif ( $numberCentralServers != 1) {
        $countErrors++;
        $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$numberCentralServers</td><td>there can be only one activated central monitoring server</td><td>&nbsp;</td></tr>";
      } else {
        $sql = "SELECT serverID, typeMonitoring, typeServers, masterFQDN, masterDatabaseFQDN, slaveFQDN, slaveDatabaseFQDN FROM $SERVERTABLSERVERS where typeMonitoring = 0 and activated = 1";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ($rv) { 
          if ( $sth->rows ) { ($centralServerID, $centralTypeMonitoring, $centralTypeServers, $centralMasterFQDN, $centralMasterDatabaseFQDN, $centralSlaveFQDN, $centralSlaveDatabaseFQDN) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID); }
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        }

        $centralSlaveDatabaseFQDN = $centralMasterDatabaseFQDN unless ( $centralTypeServers );
      }

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{TABLE}\"><td align=\"center\" colspan=\"3\">&nbsp;</td></tr>";

      # plugins uploaded <-> plugins configurated - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins Uploaded <-> Plugins Configurated</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Plugin</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT DISTINCT test FROM $SERVERTABLPLUGINS where activated = 1";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$test) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          my @plugins = glob("$PLUGINPATH/*.pl");

          while( $sth->fetch() ) {
            my $teller = 0;

            foreach my $plugin (@plugins) {
              if ( $plugin eq "$PLUGINPATH/$test" ) {
                $plugins[$teller] = undef;
                last;
              }

              $teller++
            }
          }

          foreach my $pluginPath (@plugins) {
            if (defined $pluginPath) {
		      (undef, my $plugin) = split (/^$PLUGINPATH\//, $pluginPath);
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;plugin=$plugin&amp;todo=delete\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Delete Plugin\" alt=\"Delete Plugin\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$plugin</td><td>plugin uploaded without plugin configuration</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
			}
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # plugins configurated <-> plugins uploaded - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins Configurated <-> Plugins Uploaded</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Plugin</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins Configurated <-> Plugins Uploaded</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Plugin</td><td>Message</td><td align=\"center\">Action</td></tr>";

      $sql = "SELECT DISTINCT test FROM $SERVERTABLPLUGINS where activated = 1";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$test) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if (! -e "$PLUGINPATH/$test") {
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;plugin=$test&amp;todo=edit\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Plugin\" alt=\"Edit Plugin\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$test</td><td>plugin configuration without plugin uploaded</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
            } else {
               my $sb = stat("$PLUGINPATH/$test");

               unless ( $sb->mode == 33261 or $sb->mode == 33256 ) { # 0755 = 33261 & 0750 = 33256 
                $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;plugin=$test&amp;todo=maintenance\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{maintenance}\" title=\"Rights Plugin\" alt=\"Rights Plugin\" border=\"0\"></a>";
                $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$test</td><td>plugin configuration with plugin uploaded but without wanted excecution rights</td><td align=\"center\">$actionItem</td></tr>";
                $countErrors++;
              }
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{TABLE}\"><td align=\"center\" colspan=\"3\">&nbsp;</td></tr>";

      # help plugin filenames <-> plugin  - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Help Plugin Filenames <-> Plugin</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Help Plugin Filename</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT DISTINCT helpPluginFilename FROM $SERVERTABLPLUGINS WHERE helpPluginFilename != '<NIHIL>'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$helpPluginFilename) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          my @helpPluginFilenames = glob("$PDPHELPPATH/*");

          while( $sth->fetch() ) {
            my $teller = 0;

            foreach my $helpPluginPathFilename (@helpPluginFilenames) {
              if ( $helpPluginPathFilename eq "$PDPHELPPATH/$helpPluginFilename" ) {
                $helpPluginFilenames[$teller] = undef;
                last;
              }

              $teller++
            }
          }

          foreach my $helpPluginPathFilename (@helpPluginFilenames) {
            if (defined $helpPluginPathFilename) {
		      (undef, $helpPluginFilename) = split (/^$PDPHELPPATH\//, $helpPluginPathFilename);
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;helpPluginFilename=$helpPluginFilename&amp;todo=delete\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Delete Help Plugin Filename\" alt=\"Delete Help Plugin Filename\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$helpPluginFilename</td><td>help plugin filename without plugin reference</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
			}
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # plugins <-> help plugin filename  - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Help Plugin Filename</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT uKey, LTRIM(SUBSTRING_INDEX(title, ']', -1)) as shortTitle, helpPluginFilename FROM $SERVERTABLPLUGINS WHERE activated = 1 order by shortTitle";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$title, \$helpPluginFilename) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if (! defined $helpPluginFilename or $helpPluginFilename eq '<NIHIL>') {
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;helpPluginFilename=<NIHIL>&amp;todo=duplicate\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{duplicate}\" title=\"Add Help Plugin Filename\" alt=\"Add Help Plugin Filename\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>'$title' plugin without help plugin filename defined</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
            } elsif (! -e "$PDPHELPPATH/$helpPluginFilename") {
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;helpPluginFilename=$helpPluginFilename&amp;todo=edit\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Help Plugin Filename\" alt=\"Edit Help Plugin Filename\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>'$title' plugin with missing help plugin filename '<b>$helpPluginFilename</b>'</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      $matchingErrors .= "</table>\n";
      $matchingWarnings .= "</table>\n";

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      if ($action eq 'generateView') {
        my ($rvOpen, $typeMonitoringCharDorC, $typeMonitoring, $typeServers, $masterFQDN, $slaveFQDN, $mode, $dumphttp, $status, $loop, $displayTime, $lockMySQL, $debugDaemon, $debugAllScreen, $debugAllFile, $debugNokFile);

        $initializeGenerateView .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><th>Initialize Generate Configs</th></tr>";

        $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp", $debug);
        $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR", $debug);
        $initializeGenerateView .= system_call ("rm -rf", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated", $debug);
        $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/generated", $debug);

        unless (-d "$APPLICATIONPATH/tmp/$CONFIGDIR/installed") {
          $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);
        }

        if ( defined $numberCentralServers and $numberCentralServers == 1) {
          $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CM-$centralMasterFQDN", $debug);
          $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CM-$centralMasterFQDN/etc", $debug);
          $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CM-$centralMasterFQDN/master", $debug);

		  if ( $centralTypeServers ) {
            $initializeGenerateView .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CS-$centralSlaveFQDN", $debug);
            $initializeGenerateView .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CS-$centralSlaveFQDN/etc", $debug);
            $initializeGenerateView .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CS-$centralSlaveFQDN/master", $debug);
          }
        }

        $initializeGenerateView .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/\" target=\"_blank\">Browse directory list with all config files</a></td></tr>\n      </table>";

        my $configDateTime = get_csvfiledate .' '. get_csvfiletime;
        $rvOpen = 0;

        # ArchiveCT - - - - - - - - - - - - - - - - - - - - - - - - - - -
        $sql = "select distinct $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLCRONTABS.uKey, $SERVERTABLPLUGINS.test from $SERVERTABLSERVERS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS, $SERVERTABLPLUGINS where $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = 1 and $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLPLUGINS.activated = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLCRONTABS.uKey";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$masterFQDN, \$slaveFQDN, \$collectorDaemon, \$resultsdir, \$uKey, \$test ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          if ( $sth->rows ) {
            $prevTypeServers = 0;
            $prevServerID = $prevMasterFQDN = $prevSlaveFQDN = $prevResultsdir = '';
            $matchingArchiveCT .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

            while( $sth->fetch() ) {
              if ($prevServerID ne $serverID) {
                if ($prevServerID ne '') {
                  if ($rvOpen) {
                    print ArchiveCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde ArchiveCT - $prevServerID\n";
                    close(ArchiveCT);
                    $rvOpen = 0;

                    if ($prevTypeServers) {
                      $typeMonitoringCharDorC = ($prevTypeMonitoring) ? 'D' : 'C';
                      $matchingArchiveCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$prevMasterFQDN/etc/ArchiveCT $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$prevSlaveFQDN/etc/ArchiveCT", $debug);
                    }

                    $matchingArchiveCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>ArchiveCT - $prevServerID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  }
                }

                $matchingArchiveCT .= "\n        <tr><th>ArchiveCT - $serverID</th></tr>";

                $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                $matchingArchiveCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN", $debug);
                $matchingArchiveCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc", $debug);

                if ($typeServers) {
                  $matchingArchiveCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN", $debug);
                  $matchingArchiveCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/etc", $debug);
                }

                $rvOpen = open(ArchiveCT, ">$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/ArchiveCT");

                if ($rvOpen) {
                  $matchingArchiveCT .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/ArchiveCT\" target=\"_blank\">ArchiveCT</a></td></tr>";
                  print ArchiveCT "# ArchiveCT - $serverID, generated on $configDateTime, ASNMTAP v$version or higher\n#\n# <Pagedir>#<uniqueKey>#check_nnn[|<uniqueKey>#check_mmm]\n#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n#\n_ASNMTAP#_ASNMTAP#collectorDaemonSchedulingReports.pl\n";
                }
              }

              if ($rvOpen) {
                print ArchiveCT "#\n" if ( $prevResultsdir ne $resultsdir );
                print ArchiveCT "$resultsdir#$uKey#$test\n";
              }

              $prevServerID       = $serverID;
              $prevTypeMonitoring = $typeMonitoring;
              $prevTypeServers    = $typeServers;
              $prevMasterFQDN     = $masterFQDN;
			  $prevSlaveFQDN      = $slaveFQDN;
              $prevResultsdir     = $resultsdir;
            }

            if ($rvOpen) {
              print ArchiveCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde ArchiveCT - $serverID\n";
              close(ArchiveCT);
              $rvOpen = 0;

              if ($typeServers) {
                $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                $matchingArchiveCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/ArchiveCT $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/etc/ArchiveCT", $debug);
              }

              $matchingArchiveCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>ArchiveCT - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
            }
          } else {
            $matchingArchiveCT .= "\n        <tr><td>No records found for any ArchiveCT</td></tr>";
          }

          $matchingArchiveCT .= "\n      </table>";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }

        # DisplayCT - - - - - - - - - - - - - - - - - - - - - - - - - - -
        $sql = "select distinct $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLDISPLAYDMNS.displayDaemon, $SERVERTABLDISPLAYDMNS.pagedir, $SERVERTABLDISPLAYDMNS.loop, $SERVERTABLDISPLAYDMNS.displayTime, $SERVERTABLDISPLAYDMNS.lockMySQL, $SERVERTABLDISPLAYDMNS.debugDaemon, $SERVERTABLPLUGINS.step, $SERVERTABLDISPLAYGRPS.groupTitle, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLVIEWS.uKey, concat( $SERVERTABLPLUGINS.title, ' {', $SERVERTABLCLLCTRDMNS.serverID, '}'), $SERVERTABLPLUGINS.test, $SERVERTABLPLUGINS.environment, $SERVERTABLPLUGINS.trendline, $SERVERTABLPLUGINS.helpPluginFilename from $SERVERTABLSERVERS, $SERVERTABLDISPLAYDMNS, $SERVERTABLVIEWS, $SERVERTABLPLUGINS, $SERVERTABLDISPLAYGRPS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS where $SERVERTABLSERVERS.serverID = $SERVERTABLDISPLAYDMNS.serverID and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLDISPLAYDMNS.displayDaemon = $SERVERTABLVIEWS.displayDaemon and $SERVERTABLDISPLAYDMNS.activated = 1 and $SERVERTABLVIEWS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLVIEWS.activated = 1 and $SERVERTABLVIEWS.displayGroupID = $SERVERTABLDISPLAYGRPS.displayGroupID and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLDISPLAYGRPS.activated = 1 and $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLCLLCTRDMNS.activated = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLDISPLAYDMNS.displayDaemon, $SERVERTABLDISPLAYGRPS.groupTitle, $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLVIEWS.uKey";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$masterFQDN, \$slaveFQDN, \$displayDaemon, \$pagedirs, \$loop, \$displayTime, \$lockMySQL, \$debugDaemon, \$interval, \$groupTitle, \$resultsdir, \$uKey, \$title, \$test, \$environment, \$trendline, \$helpPluginFilename ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          if ( $sth->rows ) {
            $prevTypeServers = 0;
            $prevServerID = $prevMasterFQDN = $prevSlaveFQDN = $prevDisplayDaemon = $prevGroupTitle = '';
            $matchingDisplayCT .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

            while( $sth->fetch() ) {
              if ( $prevServerID ne $serverID or $prevDisplayDaemon ne $displayDaemon ) {
				if ( $prevDisplayDaemon ne '' ) {
                  if ($rvOpen) {
                    print DisplayCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde DisplayCT-$prevDisplayDaemon - $prevServerID\n";
                    close(DisplayCT);
                    $rvOpen = 0;
                    $typeMonitoringCharDorC = ($prevTypeMonitoring) ? 'D' : 'C';
                    $matchingDisplayCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$prevMasterFQDN/etc/DisplayCT-$prevDisplayDaemon $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$prevSlaveFQDN/etc/DisplayCT-$prevDisplayDaemon", $debug) if ($prevTypeServers);
                    $matchingDisplayCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>DisplayCT-$prevDisplayDaemon, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  }
                }

                $matchingDisplayCT .= "\n        <tr><th>DisplayCT - $serverID</th></tr>" if ( $prevServerID ne $serverID and $prevDisplayDaemon ne $displayDaemon );

                $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN", $debug);
                $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc", $debug);
                $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/master", $debug);
                $matchingDisplayCT .= createDisplayCTscript ($typeMonitoringCharDorC, 'M', $masterFQDN, $centralMasterDatabaseFQDN, "master", $displayDaemon, $pagedirs, $loop, $displayTime, $lockMySQL, $debugDaemon, $debug);

                if ( $typeServers ) {
                  $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN", $debug);
                  $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave", $debug);
                  $matchingDisplayCT .= createDisplayCTscript ($typeMonitoringCharDorC, 'S', $slaveFQDN, $centralSlaveDatabaseFQDN, "slave", $displayDaemon, $pagedirs, $loop, $displayTime, $lockMySQL, $debugDaemon, $debug);
                }

                $rvOpen = open(DisplayCT, ">$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/DisplayCT-$displayDaemon");

                if ($rvOpen) {
                  $matchingDisplayCT .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/DisplayCT-$displayDaemon\" target=\"_blank\">DisplayCT-$displayDaemon</a></td></tr>";
                  print DisplayCT "# DisplayCT-$displayDaemon - $serverID, generated on $configDateTime, ASNMTAP v$version or higher\n#\n# <interval>#<groep title>#<resultsdir>#<uniqueKey>#<titel nnn>#check_nnn#<help 0|1>[|<uniqueKey>#<titel mmm>#check_mmm#<help 0|1>]\n#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n#\n";
                }
              } else {
                print DisplayCT "#\n" if ( $prevGroupTitle ne $groupTitle and $prevGroupTitle ne '' );
              }

              if ($rvOpen) {
                print DisplayCT "$interval#$groupTitle#$resultsdir#$uKey#$title#$test --environment=$environment --trendline=$trendline#";
                (! defined $helpPluginFilename or $helpPluginFilename eq '<NIHIL>') ? print DisplayCT "0" : print DisplayCT "1";
                print DisplayCT "\n";
              }

              $prevServerID       = $serverID;
              $prevTypeMonitoring = $typeMonitoring;
              $prevTypeServers    = $typeServers;
              $prevMasterFQDN     = $masterFQDN;
			  $prevSlaveFQDN      = $slaveFQDN;
              $prevDisplayDaemon  = $displayDaemon;
              $prevGroupTitle     = $groupTitle;
            }

            if ($rvOpen) {
              print DisplayCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde DisplayCT-$displayDaemon - $serverID\n";
              close(DisplayCT);
              $rvOpen = 0;
              $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
              $matchingDisplayCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/DisplayCT-$displayDaemon $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/etc/DisplayCT-$displayDaemon", $debug) if ($typeServers);
              $matchingDisplayCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>DisplayCT-$displayDaemon, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
            }
          } else {
            $matchingDisplayCT .= "        <tr><td>No records found for any DisplayCT</td></tr>\n";
          }

          $matchingDisplayCT .= "      </table>\n";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # Display Start/Stop scripts
        $sql = "select $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLDISPLAYDMNS.displayDaemon from $SERVERTABLSERVERS, $SERVERTABLDISPLAYDMNS where $SERVERTABLSERVERS.activated = 1 and $SERVERTABLSERVERS.serverID = $SERVERTABLDISPLAYDMNS.serverID and $SERVERTABLDISPLAYDMNS.activated = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLDISPLAYDMNS.displayDaemon";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$masterFQDN, \$slaveFQDN, \$displayDaemon ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          if ( $sth->rows ) {
            $prevTypeServers = 0;
            $prevServerID = $prevMasterFQDN = $prevSlaveFQDN = '';
            $matchingAsnmtapDisplayCTscript .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

            while( $sth->fetch() ) {
              if ( $prevServerID ne $serverID ) {
                if ( $prevServerID ne '' ) {
                  $matchingAsnmtapDisplayCTscript .= createAsnmtapDisplayCTscript ($prevTypeMonitoring, 'M', $prevMasterFQDN, "master", $debug);
                  $matchingAsnmtapDisplayCTscript .= createAsnmtapDisplayCTscript ($prevTypeMonitoring, 'S', $prevSlaveFQDN, "slave", $debug) if ( $prevTypeServers );
                  $matchingAsnmtapDisplayCTscript .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Display Start/Stop scripts - $prevServerID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  delete @matchingAsnmtapDisplayCTscript[0..@matchingAsnmtapDisplayCTscript];
                }

                $matchingAsnmtapDisplayCTscript .= "\n        <tr><th>Display Start/Stop scripts - $serverID</th></tr>";
              }

              push (@matchingAsnmtapDisplayCTscript, "DisplayCT-$displayDaemon.sh");
              $prevServerID       = $serverID;
              $prevTypeMonitoring = $typeMonitoring;
              $prevTypeServers    = $typeServers;
              $prevMasterFQDN     = $masterFQDN;
              $prevSlaveFQDN      = $slaveFQDN;
            }

            $matchingAsnmtapDisplayCTscript .= createAsnmtapDisplayCTscript ($typeMonitoring, 'M', $masterFQDN, "master", $debug);
            $matchingAsnmtapDisplayCTscript .= createAsnmtapDisplayCTscript ($typeMonitoring, 'S', $slaveFQDN, "slave", $debug) if ( $typeServers );
            $matchingAsnmtapDisplayCTscript .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Display Start/Stop scripts - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
          } else {
            $matchingAsnmtapDisplayCTscript .= "        <tr><td>No records found for any DisplayCT</td></tr>\n";
          }

          $matchingAsnmtapDisplayCTscript .= "      </table>\n";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }

        # CollectorCT - - - - - - - - - - - - - - - - - - - - - - - - - -
        $sql = "select $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLCLLCTRDMNS.mode, $SERVERTABLCLLCTRDMNS.dumphttp, $SERVERTABLCLLCTRDMNS.status, $SERVERTABLCLLCTRDMNS.debugDaemon, $SERVERTABLCLLCTRDMNS.debugAllScreen, $SERVERTABLCLLCTRDMNS.debugAllFile, $SERVERTABLCLLCTRDMNS.debugNokFile, $SERVERTABLCRONTABS.minute, $SERVERTABLCRONTABS.hour, $SERVERTABLCRONTABS.dayOfTheMonth, $SERVERTABLCRONTABS.monthOfTheYear, $SERVERTABLCRONTABS.dayOfTheWeek, $SERVERTABLPLUGINS.step, $SERVERTABLPLUGINS.uKey, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.test, $SERVERTABLPLUGINS.environment, $SERVERTABLPLUGINS.arguments, $SERVERTABLCRONTABS.arguments, $SERVERTABLPLUGINS.trendline, $SERVERTABLCRONTABS.noOffline from $SERVERTABLSERVERS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS, $SERVERTABLPLUGINS where $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = 1 and $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLPLUGINS.activated = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLCRONTABS.uKey, $SERVERTABLCRONTABS.linenumber";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$masterFQDN, \$slaveFQDN, \$collectorDaemon, \$mode, \$dumphttp, \$status, \$debugDaemon, \$debugAllScreen, \$debugAllFile, \$debugNokFile, \$minute, \$hour, \$dayOfTheMonth, \$monthOfTheYear, \$dayOfTheWeek, \$interval, \$uKey, \$resultsdir, \$title, \$test, \$environment, \$argumentsCommon, \$argumentsCrontab, \$trendline, \$noOffline ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          if ( $sth->rows ) {
            $prevTypeServers = 0;
            $prevServerID = $prevMasterFQDN = $prevSlaveFQDN = $prevCollectorDaemon = $prevUniqueKey = '';
            $matchingCollectorCT .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

            while( $sth->fetch() ) {
              if ( $prevServerID ne $serverID or $prevCollectorDaemon ne $collectorDaemon ) {
				if ( $prevCollectorDaemon ne '' ) {
                  if ($rvOpen) {
                    print CollectorCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde CollectorCT-$prevCollectorDaemon - $prevServerID";
                    close(CollectorCT);
                    $rvOpen = 0;
                    $typeMonitoringCharDorC = ($prevTypeMonitoring) ? 'D' : 'C';
                    $matchingCollectorCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$prevMasterFQDN/etc/CollectorCT-$prevCollectorDaemon $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$prevSlaveFQDN/etc/CollectorCT-$prevCollectorDaemon", $debug) if ($prevTypeServers);
                    $matchingCollectorCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>CollectorCT-$prevCollectorDaemon - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  }
                }

                $matchingCollectorCT .= "\n        <tr><th>CollectorCT - $serverID</th></tr>" if ( $prevServerID ne $serverID and $prevCollectorDaemon ne $collectorDaemon );

                $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN", $debug);
                $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc", $debug);
                $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/master", $debug);
                $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/slave", $debug) if ($typeMonitoring);
                $matchingCollectorCT .= createCollectorCTscript ($typeMonitoringCharDorC, 'M', $masterFQDN, $centralMasterDatabaseFQDN, "master", $collectorDaemon, $mode, $dumphttp, $status, $debugDaemon, $debugAllScreen, $debugAllFile, $debugNokFile, $debug);

                if ( $typeServers ) {                          # Failover
                  $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN", $debug);
                  $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave", $debug);
                  $matchingCollectorCT .= createCollectorCTscript ($typeMonitoringCharDorC, 'S', $slaveFQDN, $centralSlaveDatabaseFQDN, "slave", $collectorDaemon, $mode, $dumphttp, $status, $debugDaemon, $debugAllScreen, $debugAllFile, $debugNokFile, $debug);
                }

                $rvOpen = open(CollectorCT, ">$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/CollectorCT-$collectorDaemon");

                if ($rvOpen) {
                  $matchingCollectorCT .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/CollectorCT-$collectorDaemon\" target=\"_blank\">CollectorCT-$collectorDaemon</a></td></tr>";
                  print CollectorCT "# CollectorCT-$collectorDaemon - $serverID, generated on $configDateTime, ASNMTAP v$version or higher\n#\n# <minute (0-59)> <hour (0-23)> <day of the month (1-31)> <month of the year (1-12)> <day of the week (0-6 with 0=Sunday)> <interval (1-30 min)> <uniqueKey>#<resultDir>#<titel nnn>#check_nnn[#noOFFLINE|multiOFFLINE|noTEST]][|<uniqueKey>#<resultDir>#<titel mmm>#check_mmm[noOFFLINE|multiOFFLINE|noTEST]]\n#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n#\n";

                }
              } else {
                print CollectorCT "#\n" if ( $prevUniqueKey ne $uKey and $prevUniqueKey ne '');
              }

              if ($rvOpen) {
                print CollectorCT "$minute $hour $dayOfTheMonth $monthOfTheYear $dayOfTheWeek $interval $uKey#$resultsdir#$title#$test";
                print CollectorCT " --environment=$environment --trendline=$trendline";
                print CollectorCT " $argumentsCommon" if ( $argumentsCommon ne '' );
                print CollectorCT " $argumentsCrontab" if ( $argumentsCrontab ne '' );
                print CollectorCT "#$noOffline" if ( $noOffline ne '' );
                print CollectorCT "\n";
              }

              $prevServerID        = $serverID;
              $prevTypeMonitoring  = $typeMonitoring;
              $prevTypeServers     = $typeServers;
              $prevMasterFQDN      = $masterFQDN;
			  $prevSlaveFQDN       = $slaveFQDN;
              $prevCollectorDaemon = $collectorDaemon;
              $prevUniqueKey       = $uKey;
            }

            if ($rvOpen) {
              print CollectorCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde CollectorCT-$collectorDaemon - $serverID\n";
              close(CollectorCT);
              $rvOpen = 0;
              $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
              $matchingCollectorCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/etc/CollectorCT-$collectorDaemon $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/etc/CollectorCT-$collectorDaemon", $debug) if ($typeServers);
              $matchingCollectorCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>CollectorCT-$collectorDaemon - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
            }
          } else {
            $matchingCollectorCT .= "        <tr><td>No records found for any CollectorCT</td></tr>\n";
          }

          $matchingCollectorCT .= "      </table>\n";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # Collector Start/Stop scripts
        $sql = "select $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLCLLCTRDMNS.collectorDaemon from $SERVERTABLSERVERS, $SERVERTABLCLLCTRDMNS where $SERVERTABLSERVERS.activated = 1 and $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID and $SERVERTABLCLLCTRDMNS.activated = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLCLLCTRDMNS.collectorDaemon";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$masterFQDN, \$slaveFQDN, \$collectorDaemon ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          if ( $sth->rows ) {
            $prevTypeServers = 0;
            $prevServerID = $prevMasterFQDN = $prevSlaveFQDN = '';
            $matchingAsnmtapCollectorCTscript .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

            while( $sth->fetch() ) {
              if ( $prevServerID ne $serverID ) {
                if ( $prevServerID ne '' ) {
                  $matchingAsnmtapCollectorCTscript .= createAsnmtapCollectorCTscript ($prevTypeMonitoring, 'M', $prevMasterFQDN, "master", $debug);
                  $matchingAsnmtapCollectorCTscript .= createAsnmtapCollectorCTscript ($prevTypeMonitoring, 'S', $prevSlaveFQDN, "slave", $debug) if ( $prevTypeServers );
                  $matchingAsnmtapCollectorCTscript .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Collector Start/Stop scripts - $prevServerID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  delete @matchingAsnmtapCollectorCTscript[0..@matchingAsnmtapCollectorCTscript];
                }

                $matchingAsnmtapCollectorCTscript .= "\n        <tr><th>Collector Start/Stop scripts - $serverID</th></tr>";
              }

              push (@matchingAsnmtapCollectorCTscript, "CollectorCT-$collectorDaemon.sh");
              $prevServerID        = $serverID;
              $prevTypeMonitoring  = $typeMonitoring;
              $prevTypeServers     = $typeServers;
              $prevMasterFQDN      = $masterFQDN;
			  $prevSlaveFQDN       = $slaveFQDN;
            }

            $matchingAsnmtapCollectorCTscript .= createAsnmtapCollectorCTscript ($typeMonitoring, 'M', $masterFQDN, "master", $debug);
            $matchingAsnmtapCollectorCTscript .= createAsnmtapCollectorCTscript ($typeMonitoring, 'S', $slaveFQDN, "slave", $debug) if ( $typeServers );
            $matchingAsnmtapCollectorCTscript .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Collector Start/Stop scripts - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
          } else {
            $matchingAsnmtapCollectorCTscript .= "        <tr><td>No records found for any CollectorCT</td></tr>\n";
          }

          $matchingAsnmtapCollectorCTscript .= "      </table>\n";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }

        # rsync-mirror  - - - - - - - - - - - - - - - - - - - - - - - - -
        $sql = "select distinct $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLPLUGINS.resultsdir from $SERVERTABLSERVERS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS, $SERVERTABLPLUGINS where $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = 1 and $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLPLUGINS.activated = 1 order by $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.serverID, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLPLUGINS.resultsdir";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$masterFQDN, \$slaveFQDN, \$collectorDaemon, \$resultsdir ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          if ( $sth->rows ) {
            my ($matchingRsyncMirrorConfigFailover, $matchingRsyncMirrorConfigDistributed);
            $matchingRsyncMirrorConfigFailover = $matchingRsyncMirrorConfigDistributed = '';

            my ($sameServerID, $firstCollectorDaemon) = (0, 0);
            $prevTypeMonitoring = $prevTypeServers = 0;
            $prevServerID = $prevMasterFQDN = $prevSlaveFQDN = $prevCollectorDaemon = $prevResultsdir = '';
            $matchingRsyncMirror .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

            while( $sth->fetch() ) {
              $sameServerID = ($prevServerID eq $serverID ? 1 : 0);
              $firstCollectorDaemon = ($sameServerID and $prevCollectorDaemon ne $collectorDaemon ? 1 : 0);

              if ((! $sameServerID) or $firstCollectorDaemon) {
                if ($prevServerID ne '' and $prevCollectorDaemon ne '') {
                  $matchingRsyncMirror .= createRsyncMirrorScriptsFailover ($prevServerID, $prevTypeMonitoring, $prevTypeServers, $prevMasterFQDN, $prevSlaveFQDN, $prevCollectorDaemon, $matchingRsyncMirrorConfigFailover, $debug);
                  $matchingRsyncMirror .= createRsyncMirrorScriptsDistributed ($prevServerID, $prevTypeMonitoring, $prevTypeServers, $prevMasterFQDN, $prevSlaveFQDN, $centralTypeMonitoring, $centralTypeServers, $centralMasterFQDN, $centralSlaveFQDN, $prevCollectorDaemon, $matchingRsyncMirrorConfigDistributed, $debug);
                  $matchingRsyncMirror .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Rsync Mirror Scripts - $prevServerID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>" unless ($sameServerID);
                  $matchingRsyncMirrorConfigFailover = $matchingRsyncMirrorConfigDistributed = '';
                }

                $matchingRsyncMirror .= "\n        <tr><th>Rsync Mirroring Setup - $serverID</th></tr>" unless ($sameServerID);
              }

              $matchingRsyncMirrorConfigFailover    .= "$SSHLOGONNAME\@$masterFQDN:$RESULTSPATH/$resultsdir/ $RESULTSPATH/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp\n" if ($typeServers);

              if ($typeMonitoring) {
                $matchingRsyncMirrorConfigDistributed .= "$RESULTSPATH/$resultsdir/ $SSHLOGONNAME\@$centralMasterFQDN:$RESULTSPATH/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp\n";
                $matchingRsyncMirrorConfigDistributed .= "$RESULTSPATH/$resultsdir/ $SSHLOGONNAME\@$centralSlaveFQDN:$RESULTSPATH/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp\n";
              }

              $prevServerID        = $serverID;
              $prevTypeMonitoring  = $typeMonitoring;
              $prevTypeServers     = $typeServers;
              $prevMasterFQDN      = $masterFQDN;
              $prevSlaveFQDN       = $slaveFQDN;
              $prevCollectorDaemon = $collectorDaemon;
              $prevResultsdir      = $resultsdir;
            }

            $matchingRsyncMirror .= createRsyncMirrorScriptsFailover ($serverID, $typeMonitoring, $typeServers, $masterFQDN, $slaveFQDN, $collectorDaemon, $matchingRsyncMirrorConfigFailover, $debug);
            $matchingRsyncMirror .= createRsyncMirrorScriptsDistributed ($serverID, $typeMonitoring, $typeServers, $masterFQDN, $slaveFQDN, $centralTypeMonitoring, $centralTypeServers, $centralMasterFQDN, $centralSlaveFQDN, $collectorDaemon, $matchingRsyncMirrorConfigDistributed, $debug);

            $matchingRsyncMirror .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Rsync Mirror Scripts - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
          } else {
            $matchingRsyncMirror .= "\n        <tr><td>No records found for any RsyncMirror</td></tr>";
          }

          $matchingRsyncMirror .= "\n      </table>";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      }

      $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
    }
  } elsif ($action eq 'compareView') {
    $compareView .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";
    $compareView .= "\n        <tr><th>Compare Configurations</th></tr>";

    my $compareDiff = system_call ("$DIFFCOMMAND -braq -I 'generated on 20[0-9][0-9]/[0-9][0-9]/[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]'", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated $APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);

    if ($compareDiff eq '') {
      $compareView .= "\n		   <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>The generated and installed configurations are identical.</td></tr>";
    } else {
      $compareView .= "\n		   $compareDiff";
    }

    $compareView .= "\n      </table>";
  } elsif ($action eq 'installView') {
    $installView .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";
    $installView .= "\n        <tr><th>Install Configuration</th></tr>";

    if ( -e "$APPLICATIONPATH/tmp/$CONFIGDIR/generated" ) {
      my $compareDiff = system_call ("$DIFFCOMMAND -braq -E 'generated on 20[0-9][0-9]/[0-9][0-9]/[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]'", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated $APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);

      if ($compareDiff eq '') {
        $installView .= "\n		   <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>The generated and installed configurations are identical.</td></tr>";
      } else {
        $installView .= "\n        <tr><td align=\"center\">Under construction:</td></tr>";
        $installView .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{ENDBLOCK}\">$compareDiff</table></td></tr>";
        $installView .= "\n        <tr><td align=\"center\">&nbsp;</td></tr>";
        $installView .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>We only move $APPLICATIONPATH/tmp/$CONFIGDIR/generated to $APPLICATIONPATH/tmp/$CONFIGDIR/installed</td></tr>";

        $installView .= "\n        <tr align=\"left\"><td align=\"right\"><input type=\"submit\" value=\"Install\"><input type=\"reset\" value=\"Reset\"></td></tr>\n";
      }

    } else {
      $installView .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Under construction:</td></tr>";
      $installView .= "\n        <tr><td>The generated configuration doesn't exist.</td></tr>";
    }
	
    $installView .= "\n      </table>";
  } elsif ($action eq 'install') {
    $installView .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";
    $installView .= "\n        <tr><th>Configuration Installed</th></tr>";

    if ( -e "$APPLICATIONPATH/tmp/$CONFIGDIR/generated" ) {
      $installView .= system_call ("rm -rf", "$APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);
      $installView .= system_call ("mv", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated $APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);
      $installView .= "\n        <tr><td align=\"center\">Under construction:</td></tr>";
      $installView .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>We moved $APPLICATIONPATH/tmp/$CONFIGDIR/generated to $APPLICATIONPATH/tmp/$CONFIGDIR/installed</td></tr>";
    } else {
      $installView .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Under construction:</td></tr>";
      $installView .= "\n        <tr><td>The generated configuration doesn't exist.</td></tr>";
    }

    $installView .= "\n      </table>";
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

    if ($action eq 'installView') {
      print "        <form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"generateConfig\">\n";

      print <<HTML;
        <input type="hidden" name="pagedir"   value="$pagedir">
        <input type="hidden" name="pageset"   value="$pageset">
        <input type="hidden" name="debug"     value="$debug">
        <input type="hidden" name="CGISESSID" value="$sessionID">
        <input type="hidden" name="action"    value="install">
HTML
    } else {
      print "        <br>\n";
    }

    if ($action eq 'updateView' or $action eq 'update') {
      print "  <table width=\"100%\"><tr align=\"center\"><td>\n";
      print "    <table bgcolor=\"$COLORSTABLE{TABLE}\" border=\"0\" cellspacing=\"1\" cellpadding=\"1\"\n";
      print "      <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\" colspan=\"2\" align=\"center\"> <b>$action: Under Construction</b> </td></tr>\n";
      print "      <tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\"> plugin </td><td> $Cplugin </td></tr>\n";
      print "      <tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\"> help plugin filename </td><td> $ChelpPluginFilename </td></tr>\n";
      print "      <tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\"> todo </td><td> $Ctodo </td></tr>\n";
      print "    </table>\n";
      print "  </td></tr></table>\n";
    } else {
      print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=checkView">[Check Configuration]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=generateView">[Generate Configuration]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=compareView">[Compare Configurations]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=installView">[Install Generated Configuration]</a></td>
  	  </tr></table>
	</td></tr>
HTML
    }

    if ($action ne "menuView") {
      print "  <tr align=\"center\"><td>\n  <table>\n";

      if ($action eq 'checkView' or $action eq 'generateView') {
        print "    <tr align=\"center\"><td>&nbsp;</td></tr>\n    <tr align=\"center\"><td>$matchingWarnings</td></tr>\n" if ($countWarnings);
        print "    <tr align=\"center\"><td>&nbsp;</td></tr>\n    <tr align=\"center\"><td>$matchingErrors</td></tr>\n" if ($countErrors);
        print "    <tr align=\"center\"><td>&nbsp;</td></tr>\n    <tr align=\"center\"><td>Warning: $countWarnings, Errors: $countErrors</td></tr>\n";
      }

      if ($action eq 'generateView') {
        if ($countErrors == 0) {
          print <<HTML;
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$initializeGenerateView</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingArchiveCT</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingDisplayCT</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingAsnmtapDisplayCTscript</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingCollectorCT</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingAsnmtapCollectorCTscript</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingRsyncMirror</td></tr>
HTML
        } else {
          print "    <tr align=\"center\"><td>&nbsp;</td></tr>\n    <tr align=\"center\"><td>Errors: $countErrors, first solve them PLEASE</td></tr>\n";
        }
      } elsif ($action eq 'compareView') {
        print <<HTML;
    <tr align=\"center\"><td>&nbsp;</td></tr>
    <tr align=\"center\"><td>$compareView</td></tr>
HTML
      } elsif ($action eq 'installView' or $action eq 'install') {
        print <<HTML;
    <tr align=\"center\"><td>&nbsp;</td></tr>
    <tr align=\"center\"><td>$installView</td></tr>
HTML
      }

      print "  </table>\n  </td></tr>\n";
    }

    print "  </table>\n";
	
    if ($action eq 'installView') {
      print "</form>\n";
    } else {
      print "<br>\n";
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createCollectorCTscript {
  my ($typeMonitoringCharDorC, $typeServersCharMorS, $serverFQDN, $databaseFQDN, $subdir, $collectorDaemon, $mode, $dumphttp, $status, $debugDaemon, $debugAllScreen, $debugAllFile, $debugNokFile, $debug) = @_;
  
  my $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/CollectorCT-$collectorDaemon.sh";
  my $command  = "cat $APPLICATIONPATH/tools/templates/CollectorCT-template.sh >> $filename";

  my $rvOpen = open(CollectorCT, ">$filename");

  if ($rvOpen) {
    print CollectorCT <<STARTUPFILE;
#!/bin/bash
# ---------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

AMNAME=\"Collector ASNMTAP $collectorDaemon\"
AMPATH=$APPLICATIONPATH
AMCMD=collector.pl
AMPARA=\"--hostname=$databaseFQDN --mode=$mode --collectorlist=CollectorCT-$collectorDaemon --dumphttp=$dumphttp --status=$status --debug=$debugDaemon --screenDebug=$debugAllScreen --allDebug=$debugAllFile --nokDebug=$debugNokFile\"
PIDPATH=$PIDPATH
PIDNAME=CollectorCT-$collectorDaemon.pid

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ -f "\$AMPATH/sbin/bash_stop_root.sh" ]; then
  source "\$AMPATH/sbin/bash_stop_root.sh"
fi

STARTUPFILE

    close (CollectorCT);
  }

  my $statusMessage = do_system_call ($command, $debug);
  $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/CollectorCT-$collectorDaemon.sh\" target=\"_blank\">CollectorCT-$collectorDaemon.sh ($subdir)</a></td></tr>";
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createAsnmtapCollectorCTscript {
  my ($typeMonitoring, $typeServersCharMorS, $serverFQDN, $subdir, $debug) = @_;

  my $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';

  my $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/root-collector.sh";
  my $rvOpen = open(AsnmtapCollectorCTscript, ">$filename");

  if ($rvOpen) {
    print AsnmtapCollectorCTscript <<STARTUPFILE;
#!/bin/sh

su - $SSHLOGONNAME -c "cd $APPLICATIONPATH/$subdir; ./asnmtap-collector.sh \$1"
exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STARTUPFILE

    close (AsnmtapCollectorCTscript);
  }
  
  my $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/root-collector.sh\" target=\"_blank\">root-collector.sh ($subdir)</a></td></tr>";

  $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/asnmtap-collector.sh";
  $rvOpen = open(AsnmtapCollectorCTscript, ">$filename");

  if ($rvOpen) {
    print AsnmtapCollectorCTscript <<STARTUPFILE;
#!/bin/sh
# ---------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

AMNAME=\"All ASNMTAP Collectors\"
AMPATH=$APPLICATIONPATH/$subdir

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STARTUPFILE

    foreach my $choise ('start', 'stop', 'reload', 'restart', 'status') {
      print AsnmtapCollectorCTscript <<STARTUPFILE;
$choise() {
  # $choise daemons
  echo "\u$choise: '\$AMNAME' ..."
  cd \$AMPATH
STARTUPFILE

      foreach my $matchingAsnmtapCollectorCTscript (@matchingAsnmtapCollectorCTscript) { print AsnmtapCollectorCTscript "  ./$matchingAsnmtapCollectorCTscript $choise\n"; }

      print AsnmtapCollectorCTscript <<STARTUPFILE;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STARTUPFILE
    }

    print AsnmtapCollectorCTscript <<STARTUPFILE;
# See how we were called.
case "\$1" in
  start)
           start
           ;;
  stop)
           stop
           ;;
  reload)
           reload
           ;;
  restart)
           restart
           ;;
  status)
           status
           ;;
  *)
           echo "Usage: '\$AMNAME' {start|stop|reload|restart|status}"
           exit 1
esac

exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STARTUPFILE

    close (AsnmtapCollectorCTscript);
  }

  $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/asnmtap-collector.sh\" target=\"_blank\">asnmtap-collector.sh ($subdir)</a></td></tr>";
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createDisplayCTscript {
  my ($typeMonitoringCharDorC, $typeServersCharMorS, $serverFQDN, $databaseFQDN, $subdir, $displayDaemon, $pagedirs, $loop, $displayTime, $lockMySQL, $debugDaemon, $debug) = @_;

  my $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/DisplayCT-$displayDaemon.sh";
  my $command  = "cat $APPLICATIONPATH/tools/templates/DisplayCT-template.sh >> $filename";

  my $rvOpen = open(DisplayCT, ">$filename");

  if ($rvOpen) {
    print DisplayCT <<STARTUPFILE;
#!/bin/bash
# ---------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

AMNAME=\"Display ASNMTAP $displayDaemon\"
AMPATH=$APPLICATIONPATH
AMCMD=display.pl
AMPARA=\"--hostname=$databaseFQDN --checklist=DisplayCT-$displayDaemon --pagedir=$pagedirs --loop=$loop --displayTime=$displayTime --lockMySQL=$lockMySQL --debug=$debugDaemon\"
PIDPATH=$PIDPATH
PIDNAME=DisplayCT-$displayDaemon.pid
SOUNDCACHENAME=DisplayCT-$displayDaemon-sound-status.cache

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ -f "\$AMPATH/sbin/bash_stop_root.sh" ]; then
  source "\$AMPATH/sbin/bash_stop_root.sh"
fi

STARTUPFILE

    close (DisplayCT);
  }

  my $statusMessage = do_system_call ($command, $debug);
  $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/DisplayCT-$displayDaemon.sh\" target=\"_blank\">DisplayCT-$displayDaemon.sh ($subdir)</a></td></tr>";
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createAsnmtapDisplayCTscript {
  my ($typeMonitoring, $typeServersCharMorS, $serverFQDN, $subdir, $debug) = @_;

  my $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';

  my $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/root-display.sh";
  my $rvOpen = open(AsnmtapDisplayCTscript, ">$filename");

  if ($rvOpen) {
    print AsnmtapDisplayCTscript <<STARTUPFILE;
#!/bin/sh

su - $SSHLOGONNAME -c "cd $APPLICATIONPATH/$subdir; ./asnmtap-display.sh \$1"
exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STARTUPFILE

    close (AsnmtapDisplayCTscript);
  }

  my $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/root-display.sh\" target=\"_blank\">root-display.sh ($subdir)</a></td></tr>";

  $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/asnmtap-display.sh";
  $rvOpen = open(AsnmtapDisplayCTscript, ">$filename");

  if ($rvOpen) {
    print AsnmtapDisplayCTscript <<STARTUPFILE;
#!/bin/sh
# ---------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

AMNAME=\"All ASNMTAP Displays\"
AMPATH=$APPLICATIONPATH/$subdir

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STARTUPFILE

    foreach my $choise ('start', 'stop', 'reload', 'restart', 'status') {
      print AsnmtapDisplayCTscript <<STARTUPFILE;
$choise() {
  # $choise daemons
  echo "\u$choise: '\$AMNAME' ..."
  cd \$AMPATH
STARTUPFILE

      foreach my $matchingAsnmtapDisplayCTscript (@matchingAsnmtapDisplayCTscript) { print AsnmtapDisplayCTscript "  ./$matchingAsnmtapDisplayCTscript $choise\n"; }

      print AsnmtapDisplayCTscript <<STARTUPFILE;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STARTUPFILE
    }

    print AsnmtapDisplayCTscript <<STARTUPFILE;
# See how we were called.
case "\$1" in
  start)
           start
           ;;
  stop)
           stop
           ;;
  reload)
           reload
           ;;
  restart)
           restart
           ;;
  status)
           status
           ;;
  *)
           echo "Usage: '\$AMNAME' {start|stop|reload|restart|status}"
           exit 1
esac

exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STARTUPFILE

    close (AsnmtapDisplayCTscript);
  }

  $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$serverFQDN/$subdir/asnmtap-display.sh\" target=\"_blank\">asnmtap-display.sh ($subdir)</a></td></tr>";
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createRsyncMirrorScriptsFailover {
  my ($serverID, $typeMonitoring, $typeServers, $masterFQDN, $slaveFQDN, $collectorDaemon, $matchingRsyncMirrorConfigFailover, $debug) = @_;

  my $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
  my ($filename, $command, $rvOpen);
  my $statusMessage = '';

  if ( $typeServers ) {                                        # Failover
    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/master/rsync-wrapper-failover-$masterFQDN.sh";

    unless ( -e $filename ) {
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Failover between $masterFQDN and $slaveFQDN</td></tr>";
      $command  = "cat $APPLICATIONPATH/tools/templates/master/rsync-wrapper-failover-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/env perl
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-wrapper-failover.sh for asnmtap, v$version, wrapper script for rsync
#   execution via ssh key for use with rsync-mirror-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-failover-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-example.conf
# ------------------------------------------------------------------------------

use strict;

# Chroot Dir
my \$chrootDir = '$RESULTSPATH/';

# Where to log successes and failures to set to /dev/null to turn off logging.
my \$filename = "$LOGPATH/rsync-wrapper-failover-$masterFQDN.log";

# What you want sent if access is denied.
my \$denyString = 'Access Denied! Sorry';

# The real path of rsync.
my \$rsyncPath = '$RSYNCCOMMAND';

# 1 = rsync version 2.6.7 or higher or 0 = otherwise
my \$rsync_version_2_6_7_or_higher = 1;

# 1 = 'capture_exec("\$system_action")' or 0 = 'system ("\$system_action")'
my \$captureOutput = $CAPTUREOUTPUT;

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/master/rsync-wrapper-failover-$masterFQDN.sh\" target=\"_blank\">rsync-wrapper-failover-$masterFQDN.sh (master)</a></td></tr>";
    }

    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Failover Monitoring from $slaveFQDN for Collector Daemon '$collectorDaemon'</td></tr>";

    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave/rsync-mirror-failover-$slaveFQDN-$collectorDaemon.sh";
    $command  = "cat $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-template.sh >> $filename";

    $rvOpen = open(RsyncMirror, ">$filename");

    if ($rvOpen) {
      print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/bash
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-mirror-failover.sh for asnmtap, v$version, mirror script for rsync
#   execution via ssh key for use with rsync-wrapper-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-failover-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-example.conf
# ------------------------------------------------------------------------------

RMVersion='$RMVERSION'
echo "rsync-mirror-failover-$slaveFQDN-$collectorDaemon.sh version \$RMVersion"

PidPath=$PIDPATH
Rsync=$RSYNCCOMMAND
KeyRsync=$SSHKEYPATH/$SSHLOGONNAME/.ssh/$RSYNCIDENTITY
ConfFile=rsync-mirror-failover-$slaveFQDN-$collectorDaemon.conf
ConfPath=$APPLICATIONPATH/slave
Delete=' --delete --delete-after '
# AdditionalParams=''                            # --numeric-ids, -H, -v and -R
Reverse=no                                       # 'yes' -> from slave to master
                                                 # 'no'  -> from master to slave

RSYNCMIRRORFILE

      close (RsyncMirror);
    }

    $statusMessage .= do_system_call ($command, $debug);
    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave/rsync-mirror-failover-$slaveFQDN-$collectorDaemon.sh\" target=\"_blank\">rsync-mirror-failover-$slaveFQDN-$collectorDaemon.sh (slave)</a></td></tr>";

    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave/rsync-mirror-failover-$slaveFQDN-$collectorDaemon.conf";

    $rvOpen = open(RsyncMirror, ">$filename");

    if ($rvOpen) {
      print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-failover-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-example.conf
# ------------------------------------------------------------------------------

$matchingRsyncMirrorConfigFailover
RSYNCMIRRORFILE

      if ( $collectorDaemon eq 'test' ) {
        print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------

$SSHLOGONNAME\@$masterFQDN:$PLUGINPATH/ $PLUGINPATH/ -v -c -z

# ------------------------------------------------------------------------------
RSYNCMIRRORFILE
      }

      close (RsyncMirror);
    }

    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave/rsync-mirror-failover-$slaveFQDN-$collectorDaemon.conf\" target=\"_blank\">rsync-mirror-failover-$slaveFQDN-$collectorDaemon.conf (slave)</a></td></tr>";
  }
  
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createRsyncMirrorScriptsDistributed {
  my ($serverID, $typeMonitoring, $typeServers, $masterFQDN, $slaveFQDN, $centralTypeMonitoring, $centralTypeServers, $centralMasterFQDN, $centralSlaveFQDN, $collectorDaemon, $matchingRsyncMirrorConfigDistributed, $debug) = @_;

  my $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
  my ($filename, $command, $rvOpen);
  my $statusMessage = '';

  if ( $typeMonitoring ) {                                 # Distributed
    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CM-$centralMasterFQDN/master/rsync-wrapper-distributed-$centralMasterFQDN.sh";

    unless ( -e $filename ) {
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Distributed Monitoring destination $centralMasterFQDN</td></tr>";
      $command  = "cat $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/env perl
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-wrapper-failover.sh for asnmtap, v$version, wrapper script for rsync
#   execution via ssh key for use with rsync-mirror-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

use strict;

# Chroot Dir
my \$chrootDir = '$RESULTSPATH/';

# Where to log successes and failures to set to /dev/null to turn off logging.
my \$filename = "$LOGPATH/rsync-wrapper-distributed-$centralMasterFQDN.log";

# What you want sent if access is denied.
my \$denyString = 'Access Denied! Sorry';

# The real path of rsync.
my \$rsyncPath = '$RSYNCCOMMAND';

# 1 = rsync version 2.6.7 or higher or 0 = otherwise
my \$rsync_version_2_6_7_or_higher = 1;

# 1 = 'capture_exec("\$system_action")' or 0 = 'system ("\$system_action")'
my \$captureOutput = $CAPTUREOUTPUT;

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/CM-$centralMasterFQDN/master/rsync-wrapper-distributed-$centralMasterFQDN.sh\" target=\"_blank\">rsync-wrapper-distributed-$centralMasterFQDN.sh (master)</a></td></tr>";
    }

    if ( $centralTypeServers ) {
      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CS-$centralSlaveFQDN/master/rsync-wrapper-distributed-$centralSlaveFQDN.sh";

      unless ( -e $filename ) {
        $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Distributed Monitoring destination $centralSlaveFQDN</td></tr>";
        $command  = "cat $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-template.sh >> $filename";

        $rvOpen = open(RsyncMirror, ">$filename");

        if ($rvOpen) {
          print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/env perl
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-wrapper-failover.sh for asnmtap, v$version, wrapper script for rsync
#   execution via ssh key for use with rsync-mirror-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

use strict;

# Chroot Dir
my \$chrootDir = '$RESULTSPATH/';

# Where to log successes and failures to set to /dev/null to turn off logging.
my \$filename = "$LOGPATH/rsync-wrapper-distributed-$centralSlaveFQDN.log";

# What you want sent if access is denied.
my \$denyString = 'Access Denied! Sorry';

# The real path of rsync.
my \$rsyncPath = '$RSYNCCOMMAND';

# 1 = rsync version 2.6.7 or higher or 0 = otherwise
my \$rsync_version_2_6_7_or_higher = 1;

# 1 = 'capture_exec("\$system_action")' or 0 = 'system ("\$system_action")'
my \$captureOutput = $CAPTUREOUTPUT;

RSYNCMIRRORFILE

          close (RsyncMirror);
        }

        $statusMessage .= do_system_call ($command, $debug);
        $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/CS-$centralSlaveFQDN/master/rsync-wrapper-distributed-$centralSlaveFQDN.sh\" target=\"_blank\">rsync-wrapper-distributed-$centralSlaveFQDN.sh (master)</a></td></tr>";
      }

      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Distributed Monitoring from $masterFQDN for Collector Daemon '$collectorDaemon'</td></tr>";
      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/slave/rsync-mirror-distributed-$masterFQDN-$collectorDaemon.sh";
      $command  = "cat $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/bash
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-mirror-failover.sh for asnmtap, v$version, mirror script for rsync
#   execution via ssh key for use with rsync-wrapper-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

RMVersion='$RMVERSION'
echo "rsync-mirror-distributed-$masterFQDN-$collectorDaemon.sh version \$RMVersion"

PidPath=$PIDPATH
Rsync=$RSYNCCOMMAND
KeyRsync=$SSHKEYPATH/$SSHLOGONNAME/.ssh/$RSYNCIDENTITY
ConfFile=rsync-mirror-distributed-$masterFQDN-$collectorDaemon.conf
ConfPath=$APPLICATIONPATH/slave
Delete=''
# AdditionalParams=''                            # --numeric-ids, -H, -v and -R
Reverse=no                                       # 'yes' -> from slave to master
                                                 # 'no'  -> from master to slave

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
    }

    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/slave/rsync-mirror-distributed-$masterFQDN-$collectorDaemon.sh\" target=\"_blank\">rsync-mirror-distributed-$masterFQDN-$collectorDaemon.sh (slave)</a></td></tr>";

    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/slave/rsync-mirror-distributed-$masterFQDN-$collectorDaemon.conf";

    $rvOpen = open(RsyncMirror, ">$filename");

    if ($rvOpen) {
      print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

$matchingRsyncMirrorConfigDistributed
# ------------------------------------------------------------------------------
RSYNCMIRRORFILE

      close (RsyncMirror);
    }

    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$masterFQDN/slave/rsync-mirror-distributed-$masterFQDN-$collectorDaemon.conf\" target=\"_blank\">rsync-mirror-distributed-$masterFQDN-$collectorDaemon.conf (slave)</a></td></tr>";

    if ( $typeServers ) {
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Distributed Monitoring from $slaveFQDN for Collector Daemon '$collectorDaemon'</td></tr>";
      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave/rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.sh";
      $command  = "cat $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/bash
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-mirror-failover.sh for asnmtap, v$version, mirror script for rsync
#   execution via ssh key for use with rsync-wrapper-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

RMVersion='$RMVERSION'
echo "rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.sh version \$RMVersion"

PidPath=$PIDPATH
Rsync=$RSYNCCOMMAND
KeyRsync=$SSHKEYPATH/$SSHLOGONNAME/.ssh/$RSYNCIDENTITY
ConfFile=rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.conf
ConfPath=$APPLICATIONPATH/slave
Delete=''
# AdditionalParams=''                            # --numeric-ids, -H, -v and -R
Reverse=no                                       # 'yes' -> from slave to master
                                                 # 'no'  -> from master to slave

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave/rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.sh\" target=\"_blank\">rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.sh (slave)</a></td></tr>";

      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave/rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.conf";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

$matchingRsyncMirrorConfigDistributed
# ------------------------------------------------------------------------------
RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$slaveFQDN/slave/rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.conf\" target=\"_blank\">rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.conf (slave)</a></td></tr>";
    }
  }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub read_directory {
  my ($directory, $subDirectory, $htmlBefore, $htmlAfter, $debug) = @_;

  my $directoryAndFileList = ( $debug eq 'T' ) ? "$htmlBefore$directory$subDirectory$htmlAfter" : '';

  my $rvOpendir = opendir (DIR, "$directory$subDirectory");

  if ($rvOpendir) {
    while ($_ = readdir (DIR)) {
      next if ($_ eq "." or $_ eq ".." or $_ eq "HEADER.html" or $_ eq "FOOTER.html");

      if (-d "$directory$subDirectory/$_") {
        $directoryAndFileList .= read_directory("$directory", "$subDirectory/$_", $htmlBefore, $htmlAfter, $debug);
      } else {
        $directoryAndFileList .= "$htmlBefore$subDirectory/$_$htmlAfter";
      }
    }

    closedir DIR;
  }

  return ($directoryAndFileList);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub do_compare_view {
  my ($command, $details, $debug) = @_;

  sub do_compare_diff {
    my ($compareView, $type, $details, $debug) = @_;

    my ($path, $generated, $installed, $compareDiff);
    $path = $generated = $installed = '';

    if ($type == 1) {
      my (undef, $dummy) = split (/Only in generated\//, $compareView);
      ($path, $generated) = split (/: /, $dummy);
      $compareDiff = "$path/$generated added" if ( $debug eq 'T' );
    } elsif ($type == 2) {
      my (undef, $dummy) = split (/Only in installed\//, $compareView);
      ($path, $installed) = split (/: /, $dummy);
      $compareDiff = "$path/$installed removed" if ( $debug eq 'T' );
    } elsif ($type == 3) {
      my (undef, $dummy) = split (/Files /, $compareView);
      ($generated, $dummy) = split (/ and /, $dummy);
      ($installed, undef) = split (/ differ/, $dummy);
      $compareDiff = "$generated and $installed differ<BR>" if ( $debug eq 'T' );

      if ($details) {
        my $command = "$DIFFCOMMAND -bra -I 'generated on 20[0-9][0-9]/[0-9][0-9]/[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]' $APPLICATIONPATH/tmp/$CONFIGDIR/$generated $APPLICATIONPATH/tmp/$CONFIGDIR/$installed";
        my @compareDiff = `$command 2>&1`;
        foreach my $compareLine (@compareDiff) { $compareDiff .= "$compareLine<BR>"; };
      }
    }

    return ($path, $generated, $installed, $compareDiff);
  }

  my $statusMessage = '';

  my @compareView = `$command 2>&1`;

  foreach my $compareView (@compareView) {
    chomp ($compareView);
    $compareView =~ s/^\s+//g;
    $compareView =~ s/$APPLICATIONPATH\/tmp\/$CONFIGDIR\///g;

    if ($compareView ne '') {
      my ($type, $server, $path, $subpath, $generated, $installed, $compareDiff, $compareText);
      my $todo = $type = 0;

      if ( $compareView =~ /^Only in generated\// ) {
        ($path, $generated, $installed, $compareDiff) = do_compare_diff ($compareView, 1, $details, $debug);

        if ($details) {
          $compareText = "File '$path/$generated' added to the generated configuration.";
        } else {
          ($type, $server) = split (/-/, $path, 2);
          ($server, $subpath) = split (/\//, $server, 2);
          $subpath .= ($subpath eq '') ? '' : '/';
          # Copy '/opt/asnmtap-3.000.xxx/applications/tmp/$CONFIGDIR/generated/DM-distributed.citap.com/etc/DisplayCT-distributed' to 'distributed.citap.com:/opt/asnmtap-3.000.xxx/applications/etc/DisplayCT-distributed'
          #       $APPLICATIONPATH/tmp/      /generated/<------- $path -------->/<--- $generated ---->      <----- $server ----->:$APPLICATIONPATH/<---- $generated --->
          # or
          # Copy '/opt/asnmtap-3.000.xxx/applications/tmp/$CONFIGDIR/generated/CM-asnmtap.citap.be/master/CollectorCT-index.sh' to 'asnmtap.citap.be:/opt/asnmtap-3.000.xxx/applications/master/CollectorCT-index.sh'
          #       $APPLICATIONPATH/tmp/      /generated/<------- $path -------->/<----------------- $generated ---------------->      <------ $server ----->:$APPLICATIONPATH/$subpath/<------------ $generated ----------->
          $compareText = "Copy '$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$path/$generated' to '$server:$APPLICATIONPATH/$subpath$generated'";

		  if (($generated =~ /^DisplayCT-[\w-]+.sh$/) or ($generated =~ /^CollectorCT-[\w-]+.sh$/)) {
            $compareText .= '<br>';
            $compareText .= "chmod 755 $server:$APPLICATIONPATH/$subpath$generated";
            $compareText .= '<br>';
            $compareText .= "$server:$APPLICATIONPATH/$subpath$generated start";
          } elsif (($generated =~ /rsync-wrapper-distributed-[\w\-.]+.sh$/) or ($generated =~ /rsync-wrapper-failover-[\w\-.]+.sh$/)) {
            $todo = 1;
          } elsif (($generated =~ /rsync-mirror-failover-[\w\-.]+.sh$/) or ($generated =~ /rsync-mirror-distributed-[\w\-.]+.sh$/)) {
            $todo = 1;
            $compareText .= '<br>';
            $compareText .= "Add 'n-59/5 * * * * $APPLICATIONPATH/$path/$generated > /dev/null' to crontab";
          }
        }
      } elsif ( $compareView =~ /^Only in generated:/ ) {
        if ($details) {
          $compareText = "$compareView";
        } else {
          my (undef, $servername) = split (/: /, $compareView, 2);
          ($type, $server) = split (/-/, $servername, 2);
          $compareText  = "Copy $APPLICATIONPATH/tmp/$CONFIGDIR/generated/$servername to $server:$APPLICATIONPATH<br>";
          $compareText .= read_directory ("$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$servername", '', '', '<br>', $debug);

		  if ($type eq 'CM' or $type eq 'DM') {
            $compareText .= "Now 'DisplayCT-*.sh start' and 'CollectorCT-*.sh start' and add 'rsync-mirror-*.sh' to crontab!!!";
          } else {
            $compareText .= "Now add 'rsync-mirror-*.sh' to crontab!!!";
          }

		  $todo = 1;
        }
      } elsif ( $compareView =~ /^Only in installed\// ) {
        ($path, $generated, $installed, $compareDiff) = do_compare_diff ($compareView, 2, $details, $debug);

        if ($details) {
          $compareText = "File '$path/$installed' removed from the generated configuration.";
        } else {
          my ($servername, $directory) = split (/\//, $path, 2);
          ($type, $server) = split (/-/, $servername, 2);
  
		  if (($installed =~ /^DisplayCT-[\w-]+.sh$/) or ($installed =~ /^CollectorCT-[\w-]+.sh$/)) {
            $compareText  = "$server:$APPLICATIONPATH";
            $compareText .= "/$directory" if (defined $directory);
            $compareText .= "/$installed stop";
            $compareText .= '<br>';
          } elsif ((($type eq 'CS' or $type eq 'DS') and ($installed =~ /^rsync-mirror-failover-[\w\-.]+.sh$/))
                or (($type eq 'DM' or $type eq 'DS') and ($installed =~ /^rsync-mirror-distributed-[\w\-.]+.sh$/))) {
            $compareText  = "Remove $server:$APPLICATIONPATH";
            $compareText .= "/$directory" if (defined $directory);
            $compareText .= "/$installed from crontab";
            $compareText .= '<br>';
            my ($installedConf, undef) = split (/.sh/, $installed);
            $compareText .= "Remove also $server:$APPLICATIONPATH";
            $compareText .= "/$directory" if (defined $directory);
            $compareText .= "/$installedConf.conf";
            $compareText .= '<br>';
            $todo = 1;
          } elsif ((($type eq 'CM' or $type eq 'DM') and ($installed =~ /^rsync-wrapper-failover-[\w\-.]+.sh$/))
                or (($type eq 'CM' or $type eq 'CS') and ($installed =~ /^rsync-wrapper-distributed-[\w\-.]+.sh$/))) {
            $compareText  = '';
            $todo = 1;
          } else {
            $compareText  = '';
          }

          # Remove 'distributed.citap.com:/opt/asnmtap-3.000.xxx/applications/etc/DisplayCT-distributed-magweg'
          #         <----- $server ----->:$APPLICATIONPATH/<------- $installed ------->
          $compareText .= "Remove '$server:$APPLICATIONPATH";
          $compareText .= "/$directory" if (defined $directory);
          $compareText .= "/$installed'";
        }
      } elsif ( $compareView =~ /^Only in installed:/ ) {
        if ($details) {
          $compareText = "$compareView";
        } else {
          my (undef, $servername) = split (/: /, $compareView, 2);
          ($type, $server) = split (/-/, $servername, 2);
          $compareText .= read_directory ("$APPLICATIONPATH/tmp/$CONFIGDIR/generated", '', '', '<br>', $debug);
          $compareText .= "First 'DisplayCT-*.sh stop', 'CollectorCT-*.sh stop' and remove 'rsync-mirror-*.sh' from crontab!!!<br>";
          $compareText .= "Remove $server:$APPLICATIONPATH/master and/or $server:$APPLICATIONPATH/slave";
          $todo = 1;
        }
      } elsif ( $compareView =~ /^Files generated\// ) {
        ($path, $generated, $installed, $compareDiff) = do_compare_diff ($compareView, 3, $details, $debug);

        if ($details) {
          $compareText = "File '$generated' changed into the generated configuration.";
        } else {
          my (undef, $servername, $filename) = split (/\//, $generated, 3);
          ($type, $server) = split (/-/, $servername, 2);

          # Replace 'distributed.citap.be:/opt/asnmtap-3.000.xxx/applications/slave/asnmtap-display.sh' with '/opt/asnmtap-3.000.xxx/applications/tmp/$CONFIGDIR/generated/DS-distributed.citap.be/slave/asnmtap-display.sh'
          #          <----- $server ---->:$APPLICATIONPATH/<------ $filename ----->        $APPLICATIONPATH/tmp/      /<---------------------- $generated ---------------------->
          $compareText = "Replace '$server:$APPLICATIONPATH/$filename' with '$APPLICATIONPATH/tmp/$CONFIGDIR/$generated'";

		  if (($filename =~ /^etc\/DisplayCT-[\w-]+$/) or ($filename =~ /^etc\/CollectorCT-[\w-]+$/)) {
            $filename =~ s/etc\///g;
            $compareText .= '<br>';
            $compareText .= "$server:$APPLICATIONPATH/";
            $compareText .= ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave';
            $compareText .= "/$filename.sh reload";
#		  } elsif (($filename =~ /^(slave|master)\/asnmtap-display.sh$/)   or ($filename =~ /^(slave|master)\/asnmtap-collector.sh$/)
#              or ($filename =~ /^(slave|master)\/DisplayCT-[\w-]+\.sh$/) or ($filename =~ /^(slave|master)\/CollectorCT-[\w-]+\.sh$/)) {
		  } elsif (($filename =~ /^(slave|master)\/DisplayCT-[\w-]+\.sh$/) or ($filename =~ /^(slave|master)\/CollectorCT-[\w-]+\.sh$/)) {
            $compareText .= '<br>';
            $compareText .= "$server:$APPLICATIONPATH/$filename restart";
          } elsif ( $filename =~ /^master\/rsync-mirror-failover-[\w\-.]+.conf$/ or $filename =~ /^slave\/rsync-mirror-failover-[\w\-.]+.conf$/) {
            $todo = 1;
          }
        }
      } elsif ( $compareView =~ /^diff: installed: No such file or directory/ ) {
        $compareText = "The installed configuration doesn't exist.";
      } elsif ( $compareView =~ /^diff: generated: No such file or directory/ ) {
        $compareText = "The generated configuration doesn't exist.";
      } else {
        $compareText = "Under construction < $compareView >";
      }

      unless ( $details) { $compareText = "<b>$compareText</b>" if ($todo or $type eq 'CM' or $type eq 'DM'); $compareText .= '<HR>'; }

      $statusMessage .= "\n		   <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$compareView</td></tr>" if ($details or $debug eq 'T');
      $statusMessage .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$compareDiff</td></tr>" if (defined $compareDiff);
      $statusMessage .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>$compareText</td></tr>";
    }
  }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub do_system_call {
  my ($command, $debug) = @_;

  my ($stdout, $stderr, $exit_value, $signal_num, $dumped_core, $status, $statusMessage);

  if ($CAPTUREOUTPUT) {
    use IO::CaptureOutput qw(capture_exec);
   ($stdout, $stderr) = capture_exec("$command");
  } else {
    system ("$command"); $stdout = $stderr = '';
  }

  if ( $debug eq 'T' ) {
    $exit_value  = $? >> 8;
    $signal_num  = $? & 127;
    $dumped_core = $? & 128;

    $statusMessage  = "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$command: ";
    $statusMessage .= ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' ) ? 'Success' : "Failed '$stderr'";
    $statusMessage .= "</td></tr>";
  } else {
    $statusMessage = '';
  }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub system_call {
  my ($command, $parameters, $debug) = @_;

  my $doSystemCall = 0;
  my $statusMessage = '';

  if ( $command eq "mkdir" ) {
    $doSystemCall = 1 unless ( -e "$parameters" );
  } elsif ( $command eq "rm -rf" ) {
    if ($parameters =~ /$APPLICATIONPATH\/tmp\/$CONFIGDIR\// and -e "$parameters") { $doSystemCall = 1; }
  } elsif ( $command eq "cp" ) {
    if ($parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR/) { $doSystemCall = 1; }
  } elsif ( $command eq "mv" ) {
    if ($parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR/) { $doSystemCall = 1; }
  } elsif ( $command =~ /diff -braq -I/ ) {
    if ($parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR\/generated $APPLICATIONPATH\/tmp\/$CONFIGDIR\/installed/) { $statusMessage = do_compare_view("$command $parameters", 1, $debug); }
  } elsif ( $command =~ /diff -braq -E/ ) {
    $command =~ s/diff -braq -E/diff -braq -I/g;
    if ($parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR\/generated $APPLICATIONPATH\/tmp\/$CONFIGDIR\/installed/) { $statusMessage = do_compare_view("$command $parameters", 0, $debug); }
  }

  if ( $doSystemCall ) {
    $statusMessage = do_system_call ("$command $parameters", $debug);

    if ( $command eq "mkdir" and $parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR/ ) {
      $statusMessage .= do_system_call ("cp $APPLICATIONPATH/tools/templates/HEADER.html $parameters/", $debug);
      $statusMessage .= do_system_call ("cp $APPLICATIONPATH/tools/templates/FOOTER.html $parameters/", $debug);
    }
  }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
