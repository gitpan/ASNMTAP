#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/09/16, v3.000.011, servers.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.011;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :SADMIN :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "servers.pl";
my $prgtext     = "Servers";
my $version     = '3.000.011';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))            ? $cgi->param('pagedir')            : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))            ? $cgi->param('pageset')            : "sadmin";  $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))              ? $cgi->param('debug')              : "F";
my $pageNo              = (defined $cgi->param('pageNo'))             ? $cgi->param('pageNo')             : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))         ? $cgi->param('pageOffset')         : 0;
my $orderBy             = (defined $cgi->param('orderBy'))            ? $cgi->param('orderBy')            : "serverID asc";
my $action              = (defined $cgi->param('action'))             ? $cgi->param('action')             : "listView";
my $CserverID           = (defined $cgi->param('serverID'))           ? $cgi->param('serverID')           : "";
my $CserverTitle        = (defined $cgi->param('serverTitle'))        ? $cgi->param('serverTitle')        : "";
my $CmasterFQDN         = (defined $cgi->param('masterFQDN'))         ? $cgi->param('masterFQDN')         : "";
my $CmasterSSHlogon     = (defined $cgi->param('masterSSHlogon'))     ? $cgi->param('masterSSHlogon')     : "";
my $CmasterSSHpasswd    = (defined $cgi->param('masterSSHpasswd'))    ? $cgi->param('masterSSHpasswd')    : "";
my $CmasterDatabaseFQDN = (defined $cgi->param('masterDatabaseFQDN')) ? $cgi->param('masterDatabaseFQDN') : "";
my $CmasterDatabasePort = (defined $cgi->param('masterDatabasePort')) ? $cgi->param('masterDatabasePort') : "3306";
my $CslaveFQDN          = (defined $cgi->param('slaveFQDN'))          ? $cgi->param('slaveFQDN')          : "";
my $CslaveSSHlogon      = (defined $cgi->param('slaveSSHlogon'))      ? $cgi->param('slaveSSHlogon')      : "";
my $CslaveSSHpasswd     = (defined $cgi->param('slaveSSHpasswd'))     ? $cgi->param('slaveSSHpasswd')     : "";
my $CslaveDatabaseFQDN  = (defined $cgi->param('slaveDatabaseFQDN'))  ? $cgi->param('slaveDatabaseFQDN')  : "";
my $CslaveDatabasePort  = (defined $cgi->param('slaveDatabasePort'))  ? $cgi->param('slaveDatabasePort')  : "3306";
my $CtypeServers        = (defined $cgi->param('typeServers'))        ? $cgi->param('typeServers')        : 0;
my $CtypeMonitoring     = (defined $cgi->param('typeMonitoring'))     ? $cgi->param('typeMonitoring')     : 0;
my $Cactivated          = (defined $cgi->param('activated'))          ? $cgi->param('activated')          : "off";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Server ID", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&serverID=$CserverID&serverTitle=$CserverTitle&masterFQDN=$CmasterFQDN&masterSSHlogon=$CmasterSSHlogon&masterSSHpasswd=$CmasterSSHpasswd&masterDatabaseFQDN=$CmasterDatabaseFQDN&masterDatabasePort=$CmasterDatabasePort&slaveFQDN=$CslaveFQDN&slaveSSHlogon=$CslaveSSHlogon&slaveSSHpasswd=$CslaveSSHpasswd&slaveDatabaseFQDN=$CslaveDatabaseFQDN&slaveDatabasePort=$CslaveDatabasePort&typeServers=$CtypeServers&typeMonitoring=$CtypeMonitoring&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>server ID         : $CserverID<br>serverTitle       : $CserverTitle<br>masterFQDN        : $CmasterFQDN<br>masterSSHlogon    : $CmasterSSHlogon<br>masterSSHpasswd   : $CmasterSSHpasswd<br>masterDatabaseFQDN: $CmasterDatabaseFQDN<br>masterDatabasePort: $CmasterDatabasePort<br>slaveFQDN         : $CslaveFQDN<br>slaveSSHlogon     : $CslaveSSHlogon<br>slaveSSHpasswd    : $CslaveSSHpasswd<br>slaveDatabaseFQDN : $CslaveDatabaseFQDN<br>slaveDatabaseFQDN : $CslaveDatabaseFQDN<br>typeServers       : $CtypeServers<br>typeMonitoring    : $CtypeMonitoring<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($matchingServers, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = "";

    if ($action eq "duplicateView" or $action eq "insertView") {
      $htmlTitle    = "Insert Server ID";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq "insert") {
      $htmlTitle    = "Check if Server ID $CserverID exist before to insert";

      $sql = "select serverID from $SERVERTABLSERVERS WHERE serverID='$CserverID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle  = "Server ID $CserverID exist already";
        $nextAction = "insertView";
      } else {
        $htmlTitle  = "Server ID $CserverID inserted";
        my $dummyActivated = ($Cactivated eq "on") ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLSERVERS. ' SET serverID="' .$CserverID. '", serverTitle="' .$CserverTitle. '", masterFQDN="' .$CmasterFQDN. '", masterSSHlogon="' .$CmasterSSHlogon. '", masterSSHpasswd="' .$CmasterSSHpasswd. '", masterDatabaseFQDN="' .$CmasterDatabaseFQDN. '", masterDatabasePort="' .$CmasterDatabasePort. '", slaveFQDN="' .$CslaveFQDN. '", slaveSSHlogon="' .$CslaveSSHlogon. '", slaveSSHpasswd="' .$CslaveSSHpasswd. '", slaveDatabaseFQDN="' .$CslaveDatabaseFQDN. '", slaveDatabasePort="' .$CslaveDatabasePort. '", typeServers="' .$CtypeServers. '", typeMonitoring="' .$CtypeMonitoring. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq "deleteView") {
      $formDisabledPrimaryKey = $formDisabledAll = "disabled";
      $htmlTitle    = "Delete Server ID $CserverID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq "delete") {
      $sql = "select collectorDaemon, groupName from $SERVERTABLCLLCTRDMNS where serverID = '$CserverID' order by groupName";
      ($rv, $matchingServers) = check_record_exist ($rv, $dbh, $sql, 'Collector Daemon', 'Collector Daemon', 'Group Name', '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

      $sql = "select displayDaemon, groupName from $SERVERTABLDSPLYDMNS where serverID = '$CserverID' order by groupName";
      ($rv, $matchingServers) = check_record_exist ($rv, $dbh, $sql, 'Display Daemons', 'Display Daemon', 'Group Name', $matchingServers, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

	  if ($matchingServers eq "") {
        $htmlTitle = "Server ID $CserverID deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLSERVERS. ' WHERE serverID="' .$CserverID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
      } else {
        $htmlTitle = "Server ID $CserverID not deleted, still used by";
      }

      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "displayView") {
      $formDisabledPrimaryKey = $formDisabledAll = "disabled";
      $htmlTitle    = "Display Server ID $CserverID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "editView") {
      $formDisabledPrimaryKey = "disabled";
      $htmlTitle    = "Edit Server ID $CserverID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq "edit") {
      $htmlTitle    = "Server ID $CserverID updated";
      my $dummyActivated = ($Cactivated eq "on") ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLSERVERS. ' SET serverID="' .$CserverID. '", serverTitle="' .$CserverTitle. '", masterFQDN="' .$CmasterFQDN. '", masterSSHlogon="' .$CmasterSSHlogon. '", masterSSHpasswd="' .$CmasterSSHpasswd. '", masterDatabaseFQDN="' .$CmasterDatabaseFQDN. '", masterDatabasePort="' .$CmasterDatabasePort. '", slaveFQDN="' .$CslaveFQDN. '", slaveSSHlogon="' .$CslaveSSHlogon. '", slaveSSHpasswd="' .$CslaveSSHpasswd. '", slaveDatabaseFQDN="' .$CslaveDatabaseFQDN. '", slaveDatabasePort="' .$CslaveDatabasePort. '", typeServers="' .$CtypeServers. '", typeMonitoring="' .$CtypeMonitoring. '", activated="' .$dummyActivated. '" WHERE serverID="' .$CserverID. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "listView") {
      $htmlTitle    = "All Servers listed";
      $nextAction   = "listView";

      $sql = "select count(*) from $SERVERTABLSERVERS";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;orderBy=$orderBy");

      $sql = "select serverID, serverTitle, typeMonitoring, typeServers, activated from $SERVERTABLSERVERS order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverID desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Primary Key <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverTitle desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Server Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeMonitoring desc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Type Monitoring <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeMonitoring asc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeServers desc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Type Servers <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeServers asc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingServers, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Server', 'serverID', '0', '', '2#0=>Central|1=>Distributed||3#0=>Standalone|1=>Failover', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTiltle, $sessionID, $debug);
    }

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView") {
      $sql = "select serverID, serverTitle, masterFQDN, masterSSHlogon, masterSSHpasswd, masterDatabaseFQDN, masterDatabasePort, slaveFQDN, slaveSSHlogon, slaveSSHpasswd, slaveDatabaseFQDN, slaveDatabasePort, typeServers, typeMonitoring, activated from $SERVERTABLSERVERS where serverID='$CserverID'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CserverID, $CserverTitle, $CmasterFQDN, $CmasterSSHlogon, $CmasterSSHpasswd, $CmasterDatabaseFQDN, $CmasterDatabasePort, $CslaveFQDN, $CslaveSSHlogon, $CslaveSSHpasswd, $CslaveDatabaseFQDN, $CslaveDatabasePort, $CtypeServers, $CtypeMonitoring, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if ($sth->rows);
        $Cactivated = ($Cactivated == 1) ? "on" : "off";
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      }
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      my $onload = "ONLOAD=\"enableOrDisableFields();\"";
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, $onload, 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function enableOrDisableFields() {
  var typeServerDisabled = false;

  if( document.servers.typeServers.options[document.servers.typeServers.selectedIndex].value == '0' ) {
    typeServerDisabled = true;
  }

  document.servers.slaveFQDN.disabled      = typeServerDisabled;
  document.servers.slaveSSHlogon.disabled  = typeServerDisabled;
  document.servers.slaveSSHpasswd.disabled = typeServerDisabled;

  var typeMonitoringDisabled = false;

  if( document.servers.typeMonitoring.options[document.servers.typeMonitoring.selectedIndex].value == '1' ) {
    typeMonitoringDisabled = true;
    typeServerDisabled = true;
  }

  document.servers.masterDatabaseFQDN.disabled = typeMonitoringDisabled;
  document.servers.masterDatabasePort.disabled = typeMonitoringDisabled;

  document.servers.slaveDatabaseFQDN.disabled  = typeServerDisabled;
  document.servers.slaveDatabasePort.disabled  = typeServerDisabled;
}

function validateForm() {
  var objectRegularExpressionFQDNValue  = /\^[a-z|A-Z|0-9|-]\+(\\.[a-z|A-Z|0-9|-]\+)\*\$/;

  var objectRegularExpressionLogonValue = /\^[a-z|A-Z|0-9|-]\+\$/;

  // The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
  var objectRegularExpressionPasswordFormat = /\^[\\w|\\W]*(?=[\\w|\\W]*\\d)(?=[\\w|\\W]*[a-z])(?=[\\w|\\W]\*[A-Z])[\\w|\\W]*\$/;

  var objectRegularExpressionDatabasePort = /\^[0-9]\+\$/;

HTML

      if ($action eq "duplicateView" or $action eq "insertView") {
        print <<HTML;
  var objectRegularExpressionServerIDFormat = /\^[a-z|A-Z|0-9|-]\+\$/;

  if ( document.servers.serverID.value == null || document.servers.serverID.value == '' ) {
    document.servers.serverID.focus();
    alert('Please enter a server ID!');
    return false;
  } else {
    if ( ! objectRegularExpressionServerIDFormat.test(document.servers.serverID.value) ) {
      document.servers.serverID.focus();
      alert('Please re-enter server ID: Bad server ID format!');
      return false;
    }
  }
HTML
      }

      print <<HTML;
  if ( document.servers.serverTitle.value == null || document.servers.serverTitle.value == '' ) {
    document.servers.serverTitle.focus();
    alert('Please enter a server title!');
    return false;
  }

  if ( document.servers.masterFQDN.value == null || document.servers.masterFQDN.value == '' ) {
    document.servers.masterFQDN.focus();
    alert('Please enter a master FQDN!');
    return false;
  } else {
    if ( ! objectRegularExpressionFQDNValue.test(document.servers.masterFQDN.value) ) {
      document.servers.masterFQDN.focus();
      alert('Please re-enter master FQDN: Bad master FQDN value!');
      return false;
    }
  }

  if ( ! ( document.servers.masterSSHlogon.value == null || document.servers.masterSSHlogon.value == '' ) ) {
    if ( ! objectRegularExpressionLogonValue.test(document.servers.masterSSHlogon.value) ) {
      document.servers.masterSSHlogon.focus();
      alert('Please re-enter master SSH logon: Bad master SSH logon value!');
      return false;
    }
  }

  if ( ! ( document.servers.masterSSHpasswd.value == null || document.servers.masterSSHpasswd.value == '' ) ) {
    if ( ! objectRegularExpressionPasswordFormat.test(document.servers.masterSSHpasswd.value) ) {
      document.servers.masterSSHpasswd.focus();
      alert('Please re-enter master SSH passwd: Bad master SSH passwd format!');
      return false;
    }
  }

  if ( ! document.servers.masterDatabaseFQDN.disabled ) {
    if ( document.servers.masterDatabaseFQDN.value == null || document.servers.masterDatabaseFQDN.value == '' ) {
      document.servers.masterDatabaseFQDN.focus();
      alert('Please enter a master database FQDN!');
      return false;
    } else {
      if ( ! objectRegularExpressionFQDNValue.test(document.servers.masterDatabaseFQDN.value) ) {
        document.servers.masterDatabaseFQDN.focus();
        alert('Please re-enter master database FQDN: Bad master database FQDN value!');
        return false;
      }
    }

    if ( document.servers.masterDatabasePort.value == null || document.servers.masterDatabasePort.value == '' ) {
      document.servers.masterDatabasePort.focus();
      alert('Please enter a master database port!');
      return false;
    } else {
      if ( ! objectRegularExpressionDatabasePort.test(document.servers.masterDatabasePort.value) ) {
        document.servers.masterDatabasePort.focus();
        alert('Please re-enter master database port: Bad master database port value!');
        return false;
      }
    }
  }

  if( document.servers.typeServers.options[document.servers.typeServers.selectedIndex].value == '1' ) {
    if ( document.servers.slaveFQDN.value == null || document.servers.slaveFQDN.value == '' ) {
      document.servers.slaveFQDN.focus();
      alert('Please enter a slave FQDN!');
      return false;
    }

    if ( ! document.servers.slaveDatabaseFQDN.disabled ) {
      if ( document.servers.slaveDatabaseFQDN.value == null || document.servers.slaveDatabaseFQDN.value == '' ) {
        document.servers.slaveDatabaseFQDN.focus();
        alert('Please enter a slave database FQDN!');
        return false;
      }

      if ( document.servers.slaveDatabasePort.value == null || document.servers.slaveDatabasePort.value == '' ) {
        document.servers.slaveDatabasePort.focus();
        alert('Please enter a slave database port!');
        return false;
      }
    }
  }

  if ( ! (document.servers.slaveFQDN.value == null || document.servers.slaveFQDN.value == '' ) ) {
    if ( ! objectRegularExpressionFQDNValue.test(document.servers.slaveFQDN.value) ) {
      document.servers.slaveFQDN.focus();
      alert('Please re-enter slave FQDN: Bad slave FQDN value!');
      return false;
    }
  }

  if ( ! ( document.servers.slaveSSHlogon.value == null || document.servers.slaveSSHlogon.value == '' ) ) {
    if ( ! objectRegularExpressionLogonValue.test(document.servers.slaveSSHlogon.value) ) {
      document.servers.slaveSSHlogon.focus();
      alert('Please re-enter slave SSH logon: Bad slave SSH logon value!');
      return false;
    }
  }

  if ( ! (document.servers.slaveSSHpasswd.value == null || document.servers.slaveSSHpasswd.value == '') ) {
    if ( ! objectRegularExpressionPasswordFormat.test(document.servers.slaveSSHpasswd.value) ) {
      document.servers.slaveSSHpasswd.focus();
      alert('Please re-enter slave SSH passwd: Bad slave SSH passwd format!');
      return false;
    }
  }

  if ( ! (document.servers.slaveDatabaseFQDN.value == null || document.servers.slaveDatabaseFQDN.value == '' ) ) {
    if ( ! objectRegularExpressionFQDNValue.test(document.servers.slaveDatabaseFQDN.value) ) {
      document.servers.slaveDatabaseFQDN.focus();
      alert('Please re-enter slave database FQDN: Bad slave database FQDN value!');
      return false;
    }
  }

  if ( ! (document.servers.slaveDatabasePort.value == null || document.servers.slaveDatabasePort.value == '' ) ) {
    if ( ! objectRegularExpressionDatabasePort.test(document.servers.slaveDatabasePort.value) ) {
      document.servers.slaveDatabasePort.focus();
      alert('Please re-enter slave database port: Bad slave database port value!');
      return false;
    }
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="servers" onSubmit="return validateForm();">
HTML
    } elsif ($action eq "deleteView") {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"serverID\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq "deleteView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      print <<HTML;
  <input type="hidden" name="pagedir"      value="$pagedir">
  <input type="hidden" name="pageset"      value="$pageset">
  <input type="hidden" name="debug"        value="$debug">
  <input type="hidden" name="CGISESSID"    value="$sessionID">
  <input type="hidden" name="pageNo"       value="$pageNo">
  <input type="hidden" name="pageOffset"   value="$pageOffset">
  <input type="hidden" name="action"       value="$nextAction">
  <input type="hidden" name="orderBy"      value="$orderBy">
HTML
    } else {
      print "<br>\n";
    }

    print "  <input type=\"hidden\" name=\"serverID\" value=\"$CserverID\">\n" if ($formDisabledPrimaryKey ne "" and $action ne "displayView");

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=insertView&amp;orderBy=$orderBy">[Insert new Server]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=listView&amp;orderBy=$orderBy">[List all Servers]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      my $typeMonitoringSelect = create_combobox_from_keys_and_values_pairs ('0=>Central|1=>Distributed', 'K', 0, $CtypeMonitoring, 'typeMonitoring', '', '', $formDisabledAll, 'onChange="javascript:enableOrDisableFields();"', $debug);

      my $typeServersSelect = create_combobox_from_keys_and_values_pairs ('0=>Standalone|1=>Failover', 'K', 0, $CtypeServers, 'typeServers', '', '', $formDisabledAll, 'onChange="javascript:enableOrDisableFields();"', $debug);

      my $activatedChecked = ($Cactivated eq "on") ? " checked" : "";

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Server ID: </b></td><td colspan="3">
          <input type="text" name="serverID" value="$CserverID" size="11" maxlength="11" $formDisabledPrimaryKey> format: [a-z|A-Z|0-9|-]
        </td></tr><tr><td><b>Server Title: </b></td><td colspan="3">
          <input type="text" name="serverTitle" value="$CserverTitle" size="64" maxlength="64" $formDisabledAll>
        </td></tr><tr><td colspan="4">&nbsp;
    	</td></tr><tr><td><b>Type Monitoring: </b></td><td>
           $typeMonitoringSelect
        <td>&nbsp;&nbsp;<b>Type Servers: </b></td><td>
           $typeServersSelect
        </td></tr><tr><td><b>Master FQDN: </b></td><td>
          <input type="text" name="masterFQDN" value="$CmasterFQDN" size="64" maxlength="64" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave FQDN:</b> </td><td>
          <input type="text" name="slaveFQDN" value="$CslaveFQDN" size="64" maxlength="64" $formDisabledAll>
        </td></tr><tr><td>Master SSH logon: </td><td>
          <input type="text" name="masterSSHlogon" value="$CmasterSSHlogon" size="15" maxlength="15" $formDisabledAll>
        </td><td>&nbsp;&nbsp;Slave SSH logon: </td><td>
          <input type="text" name="slaveSSHlogon" value="$CslaveSSHlogon" size="15" maxlength="15" $formDisabledAll>
        </td></tr><tr><td>Master SSH passwd: </td><td>
          <input type="password" name="masterSSHpasswd" value="$CmasterSSHpasswd" size="32" maxlength="32" $formDisabledAll>
        <td>&nbsp;&nbsp;Slave SSH passwd: </td><td>
          <input type="password" name="slaveSSHpasswd" value="$CslaveSSHpasswd" size="32" maxlength="32" $formDisabledAll>
        </td></tr><tr><td><b>Master Database FQDN: </b></td><td>
          <input type="text" name="masterDatabaseFQDN" value="$CmasterDatabaseFQDN" size="64" maxlength="64" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave Database FQDN:</b> </td><td>
          <input type="text" name="slaveDatabaseFQDN" value="$CslaveDatabaseFQDN" size="64" maxlength="64" $formDisabledAll>
        <tr><td><b>Master Database Port: </b></td><td>
          <input type="text" name="masterDatabasePort" value="$CmasterDatabasePort" size="4" maxlength="4" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave Database Port:</b> </td><td>
          <input type="text" name="slaveDatabasePort" value="$CslaveDatabasePort" size="4" maxlength="4" $formDisabledAll>
        </td></tr><tr><td colspan="4">&nbsp;
        </td></tr><tr><td><b>Activated: </b></td><td colspan="3">
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td colspan=\"3\"><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq "duplicateView" or $action eq "editView" or $action eq "insertView");
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td colspan=\"3\"><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne "displayView");
      print "      </table>\n";
    } elsif ($action eq "delete" or $action eq "edit" or $action eq "insert") {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingServers</td></tr>" if (defined $matchingServers and $matchingServers ne "");
    } else {
      print "    <tr><td align=\"center\"><br>$matchingServers</td></tr>";
    }

    print "  </table>\n";

    if ($action eq "deleteView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
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

