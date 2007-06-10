#!/usr/local/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2007/06/10, v3.000.014, crontabs.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.014;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :SADMIN :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "crontabs.pl";
my $prgtext     = "Crontabs";
my $version     = do { my @r = (q$Revision: 3.000.014$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : "sadmin";  $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : "F";
my $pageNo              = (defined $cgi->param('pageNo'))          ? $cgi->param('pageNo')          : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))      ? $cgi->param('pageOffset')      : 0;
my $orderBy             = (defined $cgi->param('orderBy'))         ? $cgi->param('orderBy')         : "lineNumber asc, uKey asc, groupName asc, title asc";
my $action              = (defined $cgi->param('action'))          ? $cgi->param('action')          : "listView";
my $ClineNumber         = (defined $cgi->param('lineNumber'))      ? $cgi->param('lineNumber')      : "00";
my $CuKey               = (defined $cgi->param('uKey'))            ? $cgi->param('uKey')            : "none";
my $CcollectorDaemon    = (defined $cgi->param('collectorDaemon')) ? $cgi->param('collectorDaemon') : "none";
my $Carguments          = (defined $cgi->param('arguments'))       ? $cgi->param('arguments')       : "";
my $Cminute             = (defined $cgi->param('minute'))          ? $cgi->param('minute')          : "*";
my $Chour               = (defined $cgi->param('hour'))            ? $cgi->param('hour')            : "*";
my $CdayOfTheMonth      = (defined $cgi->param('dayOfTheMonth'))   ? $cgi->param('dayOfTheMonth')   : "*";
my $CmonthOfTheYear     = (defined $cgi->param('monthOfTheYear'))  ? $cgi->param('monthOfTheYear')  : "*";
my $CdayOfTheWeek       = (defined $cgi->param('dayOfTheWeek'))    ? $cgi->param('dayOfTheWeek')    : "*";
my $CnoOffline          = (defined $cgi->param('noOffline'))       ? $cgi->param('noOffline')       : "";
my $Cactivated          = (defined $cgi->param('activated'))       ? $cgi->param('activated')       : "off";
		
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton, $uKeySelect);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Crontabs", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&lineNumber=$ClineNumber&uKey=$CuKey&collectorDaemon=$CcollectorDaemon&arguments=$Carguments&minute=$Cminute&hour=$Chour&dayOfTheMonth=$CdayOfTheMonth&monthOfTheYear=$CmonthOfTheYear&dayOfTheWeek=$CdayOfTheWeek&noOffline=$CnoOffline&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>lineNumber        : $ClineNumber<br>uKey              : $CuKey<br>collectorDaemon   : $CcollectorDaemon<br>arguments         : $Carguments<br>minute            : $Cminute<br>hour              : $Chour<br>dayOfTheMonth     : $CdayOfTheMonth<br>monthOfTheYear    : $CmonthOfTheYear<br>dayOfTheWeek      : $CdayOfTheWeek<br>noOffline         : $CnoOffline<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($collectorDaemonSelect, $matchingCrontabs, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = "";

    if ($action eq "duplicateView" or $action eq "insertView") {
      $htmlTitle    = "Insert Crontab";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq "insert") {
      $htmlTitle    = "Check if Crontab $CuKey exist before to insert";

      $sql = "select collectorDaemon from $SERVERTABLCRONTABS WHERE lineNumber='$ClineNumber' and uKey='$CuKey'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Crontab $ClineNumber, $CuKey exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Crontab $ClineNumber, $CuKey inserted";
        my $dummyActivated = ($Cactivated eq "on") ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLCRONTABS. ' SET lineNumber="' .$ClineNumber. '", uKey="' .$CuKey. '", collectorDaemon="' .$CcollectorDaemon. '", arguments="' .$Carguments. '", minute="' .$Cminute. '", hour="' .$Chour. '", dayOfTheMonth="' .$CdayOfTheMonth. '", monthOfTheYear="' .$CmonthOfTheYear. '", dayOfTheWeek="' .$CdayOfTheWeek. '", noOffline="' .$CnoOffline. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq "crontabView") {
      $htmlTitle    = "Selected crontabs to be listed";
      $submitButton = "Crontabs";
      $nextAction   = "crontab" if ($rv);
    } elsif ($action eq "deleteView") {
      $formDisabledPrimaryKey = $formDisabledAll = "disabled";
      $htmlTitle    = "Delete crontab $ClineNumber, $CuKey";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq "delete") {
      $htmlTitle    = "Crontab $ClineNumber, $CuKey deleted";
      $sql = 'DELETE FROM ' .$SERVERTABLCRONTABS. ' WHERE lineNumber="' .$ClineNumber. '" and uKey="' .$CuKey. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "displayView") {
      $formDisabledPrimaryKey = $formDisabledAll = "disabled";
      $htmlTitle    = "Display crontab $ClineNumber, $CuKey";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "editView") {
      $formDisabledPrimaryKey = "disabled";
      $htmlTitle    = "Edit crontab $ClineNumber, $CuKey";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq "edit") {
      $htmlTitle    = "Crontab $ClineNumber, $CuKey updated";
      my $dummyActivated = ($Cactivated eq "on") ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLCRONTABS. ' SET lineNumber="' .$ClineNumber. '", uKey="' .$CuKey. '", collectorDaemon="' .$CcollectorDaemon. '", arguments="' .$Carguments. '", minute="' .$Cminute. '", hour="' .$Chour. '", dayOfTheMonth="' .$CdayOfTheMonth. '", monthOfTheYear="' .$CmonthOfTheYear. '", dayOfTheWeek="' .$CdayOfTheWeek. '", noOffline="' .$CnoOffline. '", activated="' .$dummyActivated. '" WHERE lineNumber="' .$ClineNumber. '" and uKey="' .$CuKey. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq "listView" or $action eq "crontab") {
      my ($sqlWhereCount, $sqlWhereList, $urlWithAccessParametersQuery);
      $sqlWhereCount = $sqlWhereList = $urlWithAccessParametersQuery = "";

      if ($action eq "crontab") {
        $htmlTitle      = "All selected crontabs listed";
        $nextAction     = "crontab";
	
        $sqlWhereCount  = "where $SERVERTABLCRONTABS.activated=";
        $sqlWhereCount .= ($Cactivated eq "on") ? "1" : "0";
        $sqlWhereCount .= " and $SERVERTABLCRONTABS.uKey='$CuKey'" if ($CuKey ne "none");
        $sqlWhereCount .= " and $SERVERTABLCRONTABS.collectorDaemon='$CcollectorDaemon'" if ($CcollectorDaemon ne "none");

        $sqlWhereList   = "$SERVERTABLCRONTABS.activated=";
        $sqlWhereList  .= ($Cactivated eq "on") ? "1" : "0";
        $sqlWhereList  .= " and $SERVERTABLCRONTABS.uKey='$CuKey'" if ($CuKey ne "none");
        $sqlWhereList  .= " and $SERVERTABLCRONTABS.collectorDaemon='$CcollectorDaemon'" if ($CcollectorDaemon ne "none");
        $sqlWhereList  .= " and";

        $urlWithAccessParametersQuery = "&amp;activated=$Cactivated&amp;uKey=$CuKey&amp;collectorDaemon=$CcollectorDaemon";
      } else {
        $htmlTitle      = "All crontabs listed";
        $nextAction     = "listView";
      }

      $sql = "select count(id) from $SERVERTABLCRONTABS $sqlWhereCount";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=$nextAction&orderBy=$orderBy$urlWithAccessParametersQuery");

      my ($lineNumber, $uKey, $groupName, $minute, $hour, $dayOfTheMonth, $monthOfTheYear, $dayOfTheWeek, $noOffline, $activated, $title);
      $sql = "select $SERVERTABLCRONTABS.lineNumber, $SERVERTABLCRONTABS.uKey, $SERVERTABLCLLCTRDMNS.groupName, $SERVERTABLCRONTABS.minute, $SERVERTABLCRONTABS.hour, $SERVERTABLCRONTABS.dayOfTheMonth, $SERVERTABLCRONTABS.monthOfTheYear, $SERVERTABLCRONTABS.dayOfTheWeek, $SERVERTABLCRONTABS.noOffline, $SERVERTABLCRONTABS.activated, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMNT.label, ')' ) from $SERVERTABLCRONTABS, $SERVERTABLPLUGINS, $SERVERTABLENVIRONMNT, $SERVERTABLCLLCTRDMNS where $sqlWhereList $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMNT.environment order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$lineNumber, \$uKey, \$groupName, \$minute, \$hour, \$dayOfTheMonth, \$monthOfTheYear, \$dayOfTheWeek, \$noOffline, \$activated, \$title ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        my $actionPressend = ($iconAdd or $iconDelete or $iconDetails or $iconEdit) ? 1 : 0;
        my $actionHeader = ($actionPressend) ? "<th>Action</th>" : "";
        $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;action=$nextAction$urlWithAccessParametersQuery";
        $matchingCrontabs = "\n      <table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='$COLORSTABLE{TABLE}'>\n        <tr><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=lineNumber desc, uKey asc, groupName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Primary Key <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=lineNumber asc, uKey asc, groupName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Collector Daemon <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
        $matchingCrontabs .= "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title desc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title asc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey asc, groupName asc, minute desc, hour desc, dayOfTheMonth desc, monthOfTheYear desc, dayOfTheWeek desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Crontab <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey asc, groupName asc, minute asc, hour asc, dayOfTheMonth asc, monthOfTheYear asc, dayOfTheWeek asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=noOffline desc, groupName desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> noOffline <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=noOffline desc, groupName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, groupName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, groupName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>$actionHeader</tr>\n";
        $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset";

        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            my $actionItem = ($actionPressend) ? "<td align=\"center\">&nbsp;" : "";
            my $urlWithAccessParametersAction = "$urlWithAccessParameters&amp;lineNumber=$lineNumber&amp;uKey=$uKey&amp;orderBy=$orderBy&amp;action";
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Crontabs\" alt=\"Display Crontabs\" border=\"0\"></a>&nbsp;" if ($iconDetails);
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Crontabs\" alt=\"Edit Crontabs\" border=\"0\"></a>&nbsp;" if ($iconEdit);
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=duplicateView\"><img src=\"$IMAGESURL/$ICONSRECORD{duplicate}\" title=\"Duplicate Crontabs\" alt=\"Duplicate Crontabs\" border=\"0\"></a>&nbsp;" if ($iconAdd);
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=deleteView\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Delete Crontabs\" alt=\"Delete Crontabs\" border=\"0\"></a>&nbsp;" if ($iconDelete);
            $actionItem .= "</td>" if ($actionPressend);
            $matchingCrontabs .= "        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$lineNumber-$uKey</td><td>$groupName</td><td>$title</td><td>$minute $hour $dayOfTheMonth $monthOfTheYear $dayOfTheWeek</td><td>$noOffline</td><td>$activated</td>$actionItem</tr>\n";
          }

          $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0";
        } else {
          $matchingCrontabs .= "        <tr><td colspan=\"7\">No records found for any crontab</td></tr>\n";
        }

        $matchingCrontabs .= "        <tr><td colspan=\"7\">$navigationBar</td></tr>\n" if ($navigationBar);
        $matchingCrontabs .= "      </table>\n";
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      }
    }

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView") {
      $sql = "select lineNumber, uKey, collectorDaemon, arguments, minute, hour, dayOfTheMonth, monthOfTheYear, dayOfTheWeek, noOffline, activated from $SERVERTABLCRONTABS where lineNumber='$ClineNumber' and uKey='$CuKey'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($ClineNumber, $CuKey, $CcollectorDaemon, $Carguments, $Cminute, $Chour, $CdayOfTheMonth, $CmonthOfTheYear, $CdayOfTheWeek, $CnoOffline, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if ($sth->rows);
        $Cactivated = ($Cactivated == 1) ? "on" : "off";
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      }
    }

    if ($action eq "insertView" or $action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView" or $action eq "crontabView") {
      if ($CuKey eq "none" or $action eq "duplicateView") {
        $sql = "select uKey, concat( title, ' (', $SERVERTABLENVIRONMNT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMNT where $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMNT.environment order by optionValueTitle";
      } else {
        $sql = "select uKey, concat( title, ' (', $SERVERTABLENVIRONMNT.label, ')' ) from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMNT where uKey = '$CuKey' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMNT.environment";
      }

     ($rv, $uKeySelect, $htmlTitle) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, $nextAction, $CuKey, 'uKey', 'none', '-Select-', $formDisabledPrimaryKey, '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

      $sql = "select collectorDaemon, groupName from $SERVERTABLCLLCTRDMNS order by groupName";
      ($rv, $collectorDaemonSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcollectorDaemon, 'collectorDaemon', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq "duplicateView" or $action eq "editView" or $action eq "insertView" or $action eq "crontabView") {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);

      my $crontabFormatDigits           = '(?:[0-9]{1,2})';
      my $crontabValueDigitsMin         = '(?:[0-9]|[1-5][0-9])';
      my $crontabValueDigitsHour        = '(?:[0-9]|1[0-9]|2[0-3])';
      my $crontabValueDigitsDayOfMonth  = '(?:[1-9]|[1-2][0-9]|3[0-1])';
      my $crontabValueDigitsMonthOfYear = '(?:[1-9]|1[0-2])';
      my $crontabValueDigitsDayOfWeek   = '(?:[0-6])';

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
  var objectRegularExpressionLineNumberFormat    = /\^\\d\\d\$/;

  // example: 1,2,5-9,12-16/n,19|*|*/n
  var objectRegularExpressionCrontabFormat       = /\^(?:(?:\\*\\/$crontabFormatDigits){1,1}|$crontabFormatDigits(?:[,-]$crontabFormatDigits(?:\\/$crontabFormatDigits)?)\*){1,1}\$/;

  // min (0-59)
  var objectRegularExpressionMinuteValue         = /\^(?:(?:\\*\\/$crontabValueDigitsMin){1,1}|$crontabValueDigitsMin(?:[,-]$crontabValueDigitsMin(?:\\/$crontabValueDigitsMin)?)\*){1,1}\$/;

  // hour (0-23)
  var objectRegularExpressionHourValue           = /\^(?:(?:\\*\\/$crontabValueDigitsHour){1,1}|$crontabValueDigitsHour(?:[,-]$crontabValueDigitsHour(?:\\/$crontabValueDigitsHour)?)\*){1,1}\$/;

  // day of month (1-31)
  var objectRegularExpressionDayOfTheMontValue   = /\^(?:(?:\\*\\/$crontabFormatDigits){1,1}|$crontabFormatDigits(?:[,-]$crontabFormatDigits(?:\\/$crontabFormatDigits)?)\*){1,1}\$/;

  // month of year (1-12)
  var objectRegularExpressionMontOfTheYearValue  = /\^(?:(?:\\*\\/$crontabValueDigitsMonthOfYear){1,1}|$crontabValueDigitsMonthOfYear(?:[,-]$crontabValueDigitsMonthOfYear(?:\\/$crontabValueDigitsMonthOfYear)?)\*){1,1}\$/;

  // day of week (0-6)
  var objectRegularExpressionDayOfTheWeekValue   = /\^(?:(?:\\*\\/$crontabValueDigitsDayOfWeek){1,1}|$crontabValueDigitsDayOfWeek(?:[,-]$crontabValueDigitsDayOfWeek(?:\\/$crontabValueDigitsDayOfWeek)?)\*){1,1}\$/;
HTML

      if ( $action ne "crontabView") {
        print <<HTML;

  if ( document.crontabs.collectorDaemon.options[document.crontabs.collectorDaemon.selectedIndex].value == 'none' ) {
    document.crontabs.collectorDaemon.focus();
    alert('Please select a crontab collectorDaemon!');
    return false;
  }
HTML
      }

      if ($action eq "duplicateView" or $action eq "insertView") {
        print <<HTML;

  if ( document.crontabs.lineNumber.value == null || document.crontabs.lineNumber.value == '' ) {
    document.crontabs.lineNumber.focus();
    alert('Please enter a line number!');
    return false;
  } else {
    if ( ! objectRegularExpressionLineNumberFormat.test(document.crontabs.lineNumber.value) ) {
      document.crontabs.lineNumber.focus();
      alert('Please re-enter line number: Bad line number format!');
      return false;
    }
  }

  if( document.crontabs.uKey.options[document.crontabs.uKey.selectedIndex].value == 'none' ) {
    document.crontabs.uKey.focus();
    alert('Please select one of the applications!');
    return false;
  }
HTML
      }

      if ( $action ne "crontabView") {
        print <<HTML;

  if ( document.crontabs.minute.value == null || document.crontabs.minute.value == '' ) {
    document.crontabs.minute.focus();
    alert('Please enter minute!');
    return false;
  } else {
    if ( document.crontabs.minute.value != '*' ) {
	  if ( ! objectRegularExpressionCrontabFormat.test(document.crontabs.minute.value) ) {
        document.crontabs.minute.focus();
        alert('Please re-enter minute: Bad minute format!');
        return false;
      }

	  if ( ! objectRegularExpressionMinuteValue.test(document.crontabs.minute.value) ) {
        document.crontabs.minute.focus();
        alert('Please re-enter minute: Bad minute value!');
        return false;
      }
    }
  }

  if ( document.crontabs.hour.value == null || document.crontabs.hour.value == '' ) {
    document.crontabs.hour.focus();
    alert('Please enter hour!');
    return false;
  } else {
    if ( document.crontabs.hour.value != '*'  ) {
	  if ( ! objectRegularExpressionCrontabFormat.test(document.crontabs.hour.value) ) {
        document.crontabs.hour.focus();
        alert('Please re-enter hour: Bad hour format!');
        return false;
      }

	  if ( ! objectRegularExpressionHourValue.test(document.crontabs.hour.value) ) {
        document.crontabs.hour.focus();
        alert('Please re-enter hour: Bad hour value!');
        return false;
      }
    }
  }

  if ( document.crontabs.dayOfTheMonth.value == null || document.crontabs.dayOfTheMonth.value == '' ) {
    document.crontabs.dayOfTheMonth.focus();
    alert('Please enter day of the month!');
    return false;
  } else {
    if ( document.crontabs.dayOfTheMonth.value != '*'  ) {
	  if ( ! objectRegularExpressionCrontabFormat.test(document.crontabs.dayOfTheMonth.value) ) {
        document.crontabs.dayOfTheMonth.focus();
        alert('Please re-enter day of the month: Bad day of the month format!');
        return false;
      }

	  if ( ! objectRegularExpressionDayOfTheMontValue.test(document.crontabs.dayOfTheMonth.value) ) {
        document.crontabs.dayOfTheMonth.focus();
        alert('Please re-enter day of the month: Bad day of the month value!');
        return false;
      }
    }
  }

  if ( document.crontabs.monthOfTheYear.value == null || document.crontabs.monthOfTheYear.value == '' ) {
    document.crontabs.monthOfTheYear.focus();
    alert('Please enter month of the year!');
    return false;
  } else {
    if ( document.crontabs.monthOfTheYear.value != '*' ) {
	  if ( ! objectRegularExpressionCrontabFormat.test(document.crontabs.monthOfTheYear.value) ) {
        document.crontabs.monthOfTheYear.focus();
        alert('Please re-enter month of the year: Bad month of the year format!');
        return false;
      }

	  if ( ! objectRegularExpressionMontOfTheYearValue.test(document.crontabs.monthOfTheYear.value) ) {
        document.crontabs.monthOfTheYear.focus();
        alert('Please re-enter month of the year: Bad month of the year value!');
        return false;
      }
    }
  }

  if ( document.crontabs.dayOfTheWeek.value == null || document.crontabs.dayOfTheWeek.value == '' ) {
    document.crontabs.dayOfTheWeek.focus();
    alert('Please enter day of the week!');
    return false;
  } else {
    if ( document.crontabs.dayOfTheWeek.value != '*' ) {
      if ( ! objectRegularExpressionCrontabFormat.test(document.crontabs.dayOfTheWeek.value) ) {
        document.crontabs.dayOfTheWeek.focus();
        alert('Please re-enter day of the week: Bad day of the week format!');
        return false;
      }

      if ( ! objectRegularExpressionDayOfTheWeekValue.test(document.crontabs.dayOfTheWeek.value) ) {
        document.crontabs.dayOfTheWeek.focus();
        alert('Please re-enter day of the week: Bad day of the week value!');
        return false;
      }
    }
  }
HTML
      }
	
      print <<HTML;

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="crontabs" onSubmit="return validateForm();">
HTML
    } elsif ($action eq "deleteView") {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"crontabs\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq "deleteView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView" or $action eq "crontabView") {
      print <<HTML;
  <input type="hidden" name="pagedir"        value="$pagedir">
  <input type="hidden" name="pageset"        value="$pageset">
  <input type="hidden" name="debug"          value="$debug">
  <input type="hidden" name="CGISESSID"      value="$sessionID">
  <input type="hidden" name="pageNo"         value="$pageNo">
  <input type="hidden" name="pageOffset"     value="$pageOffset">
  <input type="hidden" name="action"         value="$nextAction">
  <input type="hidden" name="orderBy"        value="$orderBy">
HTML
    } else {
      print "<br>\n";
    }

    if ($formDisabledPrimaryKey ne "" and $action ne "displayView") {
      print "  <input type=\"hidden\" name=\"uKey\"            value=\"$CuKey\">\n";
      print "  <input type=\"hidden\" name=\"lineNumber\"      value=\"$ClineNumber\">\n";
    }

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=insertView&amp;orderBy=$orderBy">[Insert new crontab]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=listView&amp;orderBy=$orderBy">[List all crontabs]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=crontabView&amp;orderBy=$orderBy">[List selected crontabs]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq "deleteView" or $action eq "displayView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView" or $action eq "crontabView") {
      my $activatedChecked = ($Cactivated eq "on") ? " checked" : "";

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Collector Daemon: </b></td><td>
          $collectorDaemonSelect
        </td></tr>
        <tr><td><b>Application: </b></td><td>
          $uKeySelect
        </td></tr>
HTML

      if ( $action ne "crontabView" ) {
      print <<HTML;
        <tr><td><b>Line Number: </b></td><td>
          <input type="text" name="lineNumber" value="$ClineNumber" size="2" maxlength="2" $formDisabledPrimaryKey>&nbsp;&nbsp;format/value: 00-99
        </td></tr>
HTML
      }

      if ( $action ne "crontabView" ) {
        my $noOfflineSelect = create_combobox_from_keys_and_values_pairs ('=>|noOFFLINE=>noOFFLINE|multiOFFLINE=>multiOFFLINE|noTEST=>noTEST', 'K', 0, $CnoOffline, 'noOffline', '', '', $formDisabledAll, '', $debug);

        print <<HTML;
        <tr><td><b>Arguments: </b></td><td>
          <input type="text" name="arguments" value="$Carguments" size="100" maxlength="254" $formDisabledAll>
        </td></tr>
        <tr><td><b>Minute: </b></td><td>
          <input type="text" name="minute" value="$Cminute" size="100" maxlength="167" $formDisabledAll>&nbsp;&nbsp;format: 0,1,2-29,30-58/2,59|*|*/n&nbsp;&nbsp;value: 0-59
        </td></tr>
        <tr><td><b>Hour: </b></td><td>
          <input type="text" name="hour" value="$Chour" size="61" maxlength="61" $formDisabledAll>&nbsp;&nbsp;format: 0,1,2-11,12-22/2,23|*|*/n&nbsp;&nbsp;value: 0-23
        </td></tr>
        <tr><td><b>Day of the Month: </b></td><td>
          <input type="text" name="dayOfTheMonth" value="$CdayOfTheMonth" size="83" maxlength="83" $formDisabledAll>&nbsp;&nbsp;format: 1,2,3-15,16-30/2,31|*|*/n&nbsp;&nbsp;value: 1-31
        </td></tr>
        <tr><td><b>Month of the Year: </b></td><td>
          <input type="text" name="monthOfTheYear" value="$CmonthOfTheYear" size="26" maxlength="26" $formDisabledAll>&nbsp;&nbsp;format: 1,2,2-6,7-11/2,12|*|*/n&nbsp;&nbsp;value: 1-12
        </td></tr>
        <tr><td><b>Day of the Week: </b></td><td>
          <input type="text" name="dayOfTheWeek" value="$CdayOfTheWeek" size="13" maxlength="13" $formDisabledAll>&nbsp;&nbsp;format: 0,1,2-3,4-5/2,6|*|*/n&nbsp;&nbsp;value: 0-6, 0: Sunday
        </td></tr>
        <tr><td><b>no Offline: </b></td><td>
          $noOfflineSelect
        </td></tr>
HTML
      }

      print <<HTML;
        <tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq "duplicateView" or $action eq "editView" or $action eq "insertView");
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne "displayView");
      print "      </table>\n";
    } elsif ($action eq "delete" or $action eq "edit" or $action eq "insert") {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingCrontabs</td></tr>" if (defined $matchingCrontabs and $matchingCrontabs ne "");
    } else {
      print "    <tr><td align=\"center\"><br>$matchingCrontabs</td></tr>";
    }

    print "  </table>\n";

    if ($action eq "deleteView" or $action eq "duplicateView" or $action eq "editView" or $action eq "insertView" or $action eq "crontabView") {
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

