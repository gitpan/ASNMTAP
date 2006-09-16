#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/09/16, v3.000.011, collectorDaemons.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "collectorDaemons.pl";
my $prgtext     = "Collector Daemons";
my $version     = '3.000.011';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : "sadmin";  $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : "F";
my $pageNo              = (defined $cgi->param('pageNo'))          ? $cgi->param('pageNo')          : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))      ? $cgi->param('pageOffset')      : 0;
my $orderBy             = (defined $cgi->param('orderBy'))         ? $cgi->param('orderBy')         : "collectorDaemon asc";
my $action              = (defined $cgi->param('action'))          ? $cgi->param('action')          : "listView";
my $CcollectorDaemon    = (defined $cgi->param('collectorDaemon')) ? $cgi->param('collectorDaemon') : "";
my $CgroupName          = (defined $cgi->param('groupName'))       ? $cgi->param('groupName')       : "";
my $CserverID           = (defined $cgi->param('serverID'))        ? $cgi->param('serverID')        : "none";
my $Cmode               = (defined $cgi->param('mode'))            ? $cgi->param('mode')            : "C";
my $Cdumphttp           = (defined $cgi->param('dumphttp'))        ? $cgi->param('dumphttp')        : "U";
my $Cstatus             = (defined $cgi->param('status'))          ? $cgi->param('status')          : "N";
my $CdebugDaemon        = (defined $cgi->param('debugDaemon'))     ? $cgi->param('debugDaemon')     : "F";
my $CdebugAllScreen     = (defined $cgi->param('debugAllScreen'))  ? $cgi->param('debugAllScreen')  : "F";
my $CdebugAllFile       = (defined $cgi->param('debugAllFile'))    ? $cgi->param('debugAllFile')    : "F";
my $CdebugNokFile       = (defined $cgi->param('debugNokFile'))    ? $cgi->param('debugNokFile')    : "F";
my $Cactivated          = (defined $cgi->param('activated'))       ? $cgi->param('activated')       : "off";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Collector Daemon", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&collectorDaemon=$CcollectorDaemon&groupName=$CgroupName&serverID=$CserverID&mode=$Cmode&dumphttp=$Cdumphttp&status=$Cstatus&debugDaemon=$CdebugDaemon&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>collectorDaemon   : $CcollectorDaemon<br>groupName         : $CgroupName<br>serverID          : $CserverID<br>mode              : $Cmode<br>dumphttp          : $Cdumphttp<br>status            : $Cstatus<br>debugAllScreen    : $CdebugAllScreen<br>debugAllFile      : $CdebugAllFile<br>debugNokFile      : $CdebugNokFile<br>debugDaemon       : $CdebugDaemon<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($serversSelect, $matchingCollectorDaemon, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = "";

    if ($action eq "duplicateView" or $action eq "insertView") {
      $htmlTitle    = "Insert Collector Daemon";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq "insert") {
      $htmlTitle    = "Check if Collector Daemon $CcollectorDaemon exist before to insert";

      $sql = "select collectorDaemon from $SERVERTABLCLLCTRDMNS WHERE collectorDaemon='$CcollectorDaemon'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle  = "Collector Daemon $CcollectorDaemon exist already";
        $nextAction = "insertView";
      } else {
        $htmlTitle  = "Collector Daemon $CcollectorDaemon inserted";
        my $dummyActivated = ($Cactivated eq "on") ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLCLLCTRDMNS. ' SET collectorDaemon="' .$CcollectorDaemon. '", groupName="' .$CgroupName. '", serverID="' .$CserverID. '", mode="' .$Cmode. '", dumphttp="' .$Cdumphttp. '", status="' .$Cstatus. '", debugDaemon="' .$CdebugDaemon. '", debugAllScreen="' .$CdebugAllScreen. '", debugAllFile="' .$CdebugAllFile. '", debugNokFile="' .$CdebugNokFile. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq "deleteView") {
      $formDisabledPrimaryKey = $formDisabledAll = "disabled";
      $htmlTitle    = "Delete Collector Daemon $CcollectorDaemon";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq "delete") {
      $sql = "select lineNumber, uKey from $SERVERTABLCRONTABS where collectorDaemon = '$CcollectorDaemon' order by uKey, lineNumber";
      ($rv, $matchingCollectorDaemon) = check_record_exist ($rv, $dbh, $sql, 'Crontabs', 'Unique Key', 'Linenumber', '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);
	
	  if ($matchingCollectorDaemon eq "") {
        $htmlTitle = "Collector Daemon $CcollectorDaemon deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLCLLCTRDMNS. ' WHERE collectorDaemon="' .$CcollectorDaemon. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
      } else {
        $htmlTitle = "Collector Daemon $CcollectorDaemon not deleted, still used by";
      }

      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "displayView") {
      $formDisabledPrimaryKey = $formDisabledAll = "disabled";
      $htmlTitle    = "Display Collector Daemon $CcollectorDaemon";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "editView") {
      $formDisabledPrimaryKey = "disabled";
      $htmlTitle    = "Edit Collector Daemon $CcollectorDaemon";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq "edit") {
      $htmlTitle    = "Collector Daemon $CcollectorDaemon updated";
      my $dummyActivated = ($Cactivated eq "on") ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLCLLCTRDMNS. ' SET collectorDaemon="' .$CcollectorDaemon. '", groupName="' .$CgroupName. '", serverID="' .$CserverID. '", mode="' .$Cmode. '", dumphttp="' .$Cdumphttp. '", status="' .$Cstatus. '", debugDaemon="' .$CdebugDaemon. '", debugAllScreen="' .$CdebugAllScreen. '", debugAllFile="' .$CdebugAllFile. '", debugNokFile="' .$CdebugNokFile. '", activated="' .$dummyActivated. '" WHERE collectorDaemon="' .$CcollectorDaemon. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "listView") {
      $htmlTitle    = "All Collector Daemons listed";

      $sql = "select count(*) from $SERVERTABLCLLCTRDMNS";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;orderBy=$orderBy");

      $sql = "select collectorDaemon, groupName, serverID, activated from $SERVERTABLCLLCTRDMNS order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=collectorDaemon desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Primary Key <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=collectorDaemon asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Group Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverID desc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> serverID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverID asc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingCollectorDaemon, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Collector Daemon', 'collectorDaemon', '0', '', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTiltle, $sessionID, $debug);
    }

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView") {
      $sql = "select collectorDaemon, groupName, serverID, mode, dumphttp, status, debugDaemon, debugAllScreen, debugAllFile, debugNokFile, activated from $SERVERTABLCLLCTRDMNS where collectorDaemon='$CcollectorDaemon'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcollectorDaemon, $CgroupName, $CserverID, $Cmode, $Cdumphttp, $Cstatus, $CdebugDaemon, $CdebugAllScreen, $CdebugAllFile, $CdebugNokFile, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if ($sth->rows);

        $Cactivated = ($Cactivated == 1) ? "on" : "off";
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      }
    }

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      $sql = "select serverID, serverTitle from $SERVERTABLSERVERS order by serverTitle";
      ($rv, $serversSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CserverID, 'serverID', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
HTML

      if ($action eq "duplicateView" or $action eq "insertView") {
        print <<HTML;

  var objectRegularExpressionCollectorDaemonFormat = /\^[a-z|A-Z|0-9|-]\+\$/;

  if ( document.collectorDaemon.collectorDaemon.value == null || document.collectorDaemon.collectorDaemon.value == '' ) {
    document.collectorDaemon.collectorDaemon.focus();
    alert('Please enter a collector daemon!');
    return false;
  } else {
    if ( ! objectRegularExpressionCollectorDaemonFormat.test(document.collectorDaemon.collectorDaemon.value) ) {
      document.collectorDaemon.collectorDaemon.focus();
      alert('Please re-enter collector daemon: Bad collector daemon format!');
      return false;
    }
  }
HTML
      }

      print <<HTML;

  if ( document.collectorDaemon.groupName.value == null || document.collectorDaemon.groupName.value == '' ) {
    document.collectorDaemon.groupName.focus();
    alert('Please enter a group name!');
    return false;
  }

  if( document.collectorDaemon.serverID.options[document.collectorDaemon.serverID.selectedIndex].value == 'none' ) {
    document.collectorDaemon.serverID.focus();
    alert('Please select one of the servers!');
    return false;
  }

  var objectRegularExpressionModeValue = /\^[O|L|C]\$/;

  if ( document.collectorDaemon.mode.value == null || document.collectorDaemon.mode.value == '' ) {
    document.collectorDaemon.mode.focus();
    alert('Please enter a mode!');
    return false;
  } else {
    if ( ! objectRegularExpressionModeValue.test(document.collectorDaemon.mode.value) ) {
      document.collectorDaemon.mode.focus();
      alert('Please re-enter mode: Bad mode value!');
      return false;
    }
  }

  var objectRegularExpressionDumphttpValue = /\^[N|A|W|C|U]\$/;

  if ( document.collectorDaemon.dumphttp.value == null || document.collectorDaemon.dumphttp.value == '' ) {
    document.collectorDaemon.dumphttp.focus();
    alert('Please enter a dumphttp!');
    return false;
  } else {
    if ( ! objectRegularExpressionDumphttpValue.test(document.collectorDaemon.dumphttp.value) ) {
      document.collectorDaemon.dumphttp.focus();
      alert('Please re-enter dumphttp: Bad dumphttp value!');
      return false;
    }
  }

  var objectRegularExpressionStatusValue = /\^[N|S]\$/;

  if ( document.collectorDaemon.status.value == null || document.collectorDaemon.status.value == '' ) {
    document.collectorDaemon.status.focus();
    alert('Please enter a status!');
    return false;
  } else {
    if ( ! objectRegularExpressionStatusValue.test(document.collectorDaemon.status.value) ) {
      document.collectorDaemon.status.focus();
      alert('Please re-enter status: Bad status value!');
      return false;
    }
  }

  var objectRegularExpressionDebugDaemonValue = /\^[F|T|L]\$/;

  if ( document.collectorDaemon.debugDaemon.value == null || document.collectorDaemon.debugDaemon.value == '' ) {
    document.collectorDaemon.debugDaemon.focus();
    alert('Please enter a debug daemon value!');
    return false;
  } else {
    if ( ! objectRegularExpressionDebugDaemonValue.test(document.collectorDaemon.debugDaemon.value) ) {
      document.collectorDaemon.debugDaemon.focus();
      alert('Please re-enter debug daemon value: Bad debug daemon value!');
      return false;
    }
  }

  var objectRegularExpressionDebugAsnmtapEnvValue = /\^[F|T]\$/;

  if ( document.collectorDaemon.debugAllScreen.value == null || document.collectorDaemon.debugAllScreen.value == '' ) {
    document.collectorDaemon.debugAllScreen.focus();
    alert('Please enter a debug all screen value!');
    return false;
  } else {
    if ( ! objectRegularExpressionDebugAsnmtapEnvValue.test(document.collectorDaemon.debugAllScreen.value) ) {
      document.collectorDaemon.debugAllScreen.focus();
      alert('Please re-enter debug all screen value: Bad debug all screen value!');
      return false;
    }
  }

  if ( document.collectorDaemon.debugAllFile.value == null || document.collectorDaemon.debugAllFile.value == '' ) {
    document.collectorDaemon.debugAllFile.focus();
    alert('Please enter a debug all file value!');
    return false;
  } else {
    if ( ! objectRegularExpressionDebugAsnmtapEnvValue.test(document.collectorDaemon.debugAllFile.value) ) {
      document.collectorDaemon.debugAllFile.focus();
      alert('Please re-enter debug all file value: Bad debug all file value!');
      return false;
    }
  }

  if ( document.collectorDaemon.debugNokFile.value == null || document.collectorDaemon.debugNokFile.value == '' ) {
    document.collectorDaemon.debugNokFile.focus();
    alert('Please enter a debug NOK file value!');
    return false;
  } else {
    if ( ! objectRegularExpressionDebugAsnmtapEnvValue.test(document.collectorDaemon.debugNokFile.value) ) {
      document.collectorDaemon.debugNokFile.focus();
      alert('Please re-enter debug NOK file value: Bad debug NOK file value!');
      return false;
    }
  }
  
  if ( document.collectorDaemon.groupName.value == null || document.collectorDaemon.groupName.value == '' ) {
    document.collectorDaemon.groupName.focus();
    alert('Please enter a group name!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="collectorDaemon" onSubmit="return validateForm();">
HTML
    } elsif ($action eq "deleteView") {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"collectorDaemon\">\n";
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

    print "  <input type=\"hidden\" name=\"collectorDaemon\" value=\"$CcollectorDaemon\">\n" if ($formDisabledPrimaryKey ne "" and $action ne "displayView");

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=insertView&amp;orderBy=$orderBy">[Insert new Collector Daemon]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=listView&amp;orderBy=$orderBy">[List all Collector Daemons]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView") {
      my $activatedChecked = ($Cactivated eq "on") ? " checked" : "";

      print <<HTML;
      <tr><td>&nbsp;</td></tr>
      <tr><td>
	    <table border="0" cellspacing="0" cellpadding="0">
          <tr><td><b>Collector Daemon: </b></td><td>
            <input type="text" name="collectorDaemon" value="$CcollectorDaemon" size="64" maxlength="64" $formDisabledPrimaryKey>
          <tr><td><b>Group Name: </b></td><td>
            <input type="text" name="groupName" value="$CgroupName" size="64" maxlength="64" $formDisabledAll>
          <tr><td><b>Server ID: </b></td><td>
            $serversSelect
          <tr><td><b>Mode: </b></td><td>
            <input type="text" name="mode" value="$Cmode" size="1" maxlength="1" $formDisabledAll> value: O(nce), L(oop) or C(rontab)
          <tr><td><b>Dumphttp: </b></td><td>
            <input type="text" name="dumphttp" value="$Cdumphttp" size="1" maxlength="1" $formDisabledAll> value: N(one), A(ll), W(arning), C(ritical) or U(nknown)
          <tr><td><b>Status: </b></td><td>
            <input type="text" name="status" value="$Cstatus" size="1" maxlength="1" $formDisabledAll> value: N(agios) or S(nmp)
          <tr><td><b>Debug Daemon: </b></td><td>
            <input type="text" name="debugDaemon" value="$CdebugDaemon" size="1" maxlength="1" $formDisabledAll>format: F(alse) or T(true) or L(ong)
          <tr><td><b>Debug All Screen: </b></td><td>
            <input type="text" name="debugAllScreen" value="$CdebugAllScreen" size="1" maxlength="1" $formDisabledAll>format: F(alse) or T(true)
          <tr><td><b>Debug All File: </b></td><td>
            <input type="text" name="debugAllFile" value="$CdebugAllFile" size="1" maxlength="1" $formDisabledAll>format: F(alse) or T(true)
          <tr><td><b>Debug NOK File: </b></td><td>
            <input type="text" name="debugNokFile" value="$CdebugNokFile" size="1" maxlength="1" $formDisabledAll>format: F(alse) or T(true)
          <tr><td><b>Activated: </b></td><td>
            <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
          </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq "duplicateView" or $action eq "editView" or $action eq "insertView");
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne "displayView");
      print "      </table>\n";
    } elsif ($action eq "delete" or $action eq "edit" or $action eq "insert") {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingCollectorDaemon</td></tr>" if (defined $matchingCollectorDaemon and $matchingCollectorDaemon ne "");
    } else {
      print "    <tr><td align=\"center\"><br>$matchingCollectorDaemon</td></tr>";
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

