#!/usr/local/bin/perl
# ---------------------------------------------------------------------------------------------------------
# � Copyright 2003-2007 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2007/10/21, v3.000.015, reports.pl for ASNMTAP::Asnmtap::Applications::CGI
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

use ASNMTAP::Asnmtap::Applications::CGI v3.000.015;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :ADMIN :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "reports.pl";
my $prgtext     = "Reports";
my $version     = do { my @r = (q$Revision: 3.000.015$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir                = (defined $cgi->param('pagedir'))               ? $cgi->param('pagedir')               : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset                = (defined $cgi->param('pageset'))               ? $cgi->param('pageset')               : 'admin';   $pageset =~ s/\+/ /g;
my $debug                  = (defined $cgi->param('debug'))                 ? $cgi->param('debug')                 : 'F';
my $pageNo                 = (defined $cgi->param('pageNo'))                ? $cgi->param('pageNo')                : 1;
my $pageOffset             = (defined $cgi->param('pageOffset'))            ? $cgi->param('pageOffset')            : 0;
my $orderBy                = (defined $cgi->param('orderBy'))               ? $cgi->param('orderBy')               : 'title';
my $action                 = (defined $cgi->param('action'))                ? $cgi->param('action')                : 'listView';
my $Cid                    = (defined $cgi->param('id'))                    ? $cgi->param('id')                    : 'new';
my $CuKey                  = (defined $cgi->param('uKey'))                  ? $cgi->param('uKey')                  : 'none';
my $Cperiode               = (defined $cgi->param('periode'))               ? $cgi->param('periode')               : 'none';
my $CtimeperiodID          = (defined $cgi->param('timeperiodID'))          ? $cgi->param('timeperiodID')          : 'none';
my $Cstatus                = (defined $cgi->param('status'))                ? $cgi->param('status')                : 'off';
my $CerrorDetails          = (defined $cgi->param('errorDetails'))          ? $cgi->param('errorDetails')          : 'off';
my $Cbar                   = (defined $cgi->param('bar'))                   ? $cgi->param('bar')                   : 'off';
my $ChourlyAverage         = (defined $cgi->param('hourlyAverage'))         ? $cgi->param('hourlyAverage')         : 'off';
my $CdailyAverage          = (defined $cgi->param('dailyAverage'))          ? $cgi->param('dailyAverage')          : 'off';
my $CshowDetails           = (defined $cgi->param('showDetails'))           ? $cgi->param('showDetails')           : 'off';
my $CshowComments          = (defined $cgi->param('showComments'))          ? $cgi->param('showComments')          : 'off';
my $CshowPerfdata          = (defined $cgi->param('showPerfdata'))          ? $cgi->param('showPerfdata')          : 'off';
my $CshowTop20SlowTests    = (defined $cgi->param('showTop20SlowTests'))    ? $cgi->param('showTop20SlowTests')    : 'off';
my $CprinterFriendlyOutput = (defined $cgi->param('printerFriendlyOutput')) ? $cgi->param('printerFriendlyOutput') : 'off';
my $CformatOutput          = (defined $cgi->param('formatOutput'))          ? $cgi->param('formatOutput')          : 'none';
my $CuserPassword          = (defined $cgi->param('userPassword'))          ? $cgi->param('userPassword')          : '';
my $Cactivated             = (defined $cgi->param('activated'))             ? $cgi->param('activated')             : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton, $uKeySelect);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Reports", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&id=$Cid&uKey=$CuKey&periode=$Cperiode&timeperiodID=$CtimeperiodID&status=$Cstatus&errorDetails=$CerrorDetails&bar=$Cbar&hourlyAverage=$ChourlyAverage&dailyAverage=$CdailyAverage&showDetails=$CshowDetails&showComments=$CshowComments&showPerfdata=$CshowPerfdata&showTop20SlowTests=$CshowTop20SlowTests&printerFriendlyOutput=$CprinterFriendlyOutput&formatOutput=$CformatOutput&userPassword=$CuserPassword&activated=$Cactivated";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>page no       : $pageNo<br>page offset   : $pageOffset<br>order by      : $orderBy<br>action        : $action<br>id            : $Cid<br>uKey          : $CuKey<br>periode       : $Cperiode<br>SLA window    : $CtimeperiodID<br>status        : $Cstatus<br>error details : $CerrorDetails<br>bar           : $Cbar<br>hourly average: $ChourlyAverage<br>daily average : $CdailyAverage<br>show details  : $CshowDetails<br>show comments : $CshowComments<br>show perfdata : $CshowPerfdata<br>20 slow tests : $CshowTop20SlowTests<br>printfriendly : $CprinterFriendlyOutput<br>format output : $CformatOutput<br>user password : $CuserPassword<br>activated     : $Cactivated<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($matchingReports, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset";

  # open connection to database and query data
  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = ''; $formDisabledPrimaryKey = "disabled";

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Report";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Report $Cid exist before to insert";

      $sql = "select id from $SERVERTABLREPORTS WHERE id='$Cid'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Report $Cid exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Report $Cid inserted";
        my $dummyStatus                = ($Cstatus eq 'on') ? 1 : 0;
        my $dummyErrorDetails          = ($CerrorDetails eq 'on') ? 1 : 0;
        my $dummyBar                   = ($Cbar eq 'on') ? 1 : 0;
        my $dummyHourlyAverage         = ($ChourlyAverage eq 'on') ? 1 : 0;
        my $dummyDailyAverage          = ($CdailyAverage eq 'on') ? 1 : 0;
        my $dummyShowDetails           = ($CshowDetails eq 'on') ? 1 : 0;
        my $dummyShowComments          = ($CshowComments eq 'on') ? 1 : 0;
        my $dummyShowPerfdata          = ($CshowPerfdata eq 'on') ? 1 : 0;
        my $dummyShowTop20SlowTests    = ($CshowTop20SlowTests eq 'on') ? 1 : 0;
        my $dummyPrinterFriendlyOutput = ($CprinterFriendlyOutput eq 'on') ? 1 : 0;
        my $dummyActivated             = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLREPORTS. ' SET uKey="' .$CuKey. '", periode="' .$Cperiode. '", timeperiodID="' .$CtimeperiodID. '", status="' .$dummyStatus. '", errorDetails="' .$dummyErrorDetails. '", bar="' .$dummyBar. '", hourlyAverage="' .$dummyHourlyAverage. '", dailyAverage="' .$dummyDailyAverage. '", showDetails="' .$dummyShowDetails. '", showComments="' .$dummyShowComments. '", showPerfdata="' .$dummyShowPerfdata. '", showTop20SlowTests="' .$dummyShowTop20SlowTests. '", printerFriendlyOutput="' .$dummyPrinterFriendlyOutput. '", formatOutput="' .$CformatOutput. '", userPassword="' .$CuserPassword. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledAll = "disabled";
      $htmlTitle    = "Delete Report $Cid";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $matchingReports = "<h1>Reports Perfdata:</h1><table><th>ID</th><th>METRIC ID</th></tr></table>\n";

      $sql = "select id, metric_id from $SERVERTABLREPORTSPRFDT where id = '$Cid' order by id";
      ($rv, $matchingReports) = check_record_exist ($rv, $dbh, $sql, 'Reports', 'ID', 'METRIC ID', $matchingReports, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      if ($matchingReports eq '') {
        $sql = 'DELETE FROM ' .$SERVERTABLREPORTS. ' WHERE id="' .$Cid. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
        $htmlTitle = "Report $Cid deleted";
      } else {
        $htmlTitle = "Report $Cid not deleted, still used by";
      }
    } elsif ($action eq 'displayView') {
      $formDisabledAll = "disabled";
      $htmlTitle    = "Display report $Cid";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $htmlTitle    = "Edit report $Cid";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "Report $Cid updated";
      my $dummyStatus                = ($Cstatus eq 'on') ? 1 : 0;
      my $dummyErrorDetails          = ($CerrorDetails eq 'on') ? 1 : 0;
      my $dummyBar                   = ($Cbar eq 'on') ? 1 : 0;
      my $dummyHourlyAverage         = ($ChourlyAverage eq 'on') ? 1 : 0;
      my $dummyDailyAverage          = ($CdailyAverage eq 'on') ? 1 : 0;
      my $dummyShowDetails           = ($CshowDetails eq 'on') ? 1 : 0;
      my $dummyShowComments          = ($CshowComments eq 'on') ? 1 : 0;
      my $dummyShowPerfdata          = ($CshowPerfdata eq 'on') ? 1 : 0;
      my $dummyShowTop20SlowTests    = ($CshowTop20SlowTests eq 'on') ? 1 : 0;
      my $dummyPrinterFriendlyOutput = ($CprinterFriendlyOutput eq 'on') ? 1 : 0;
      my $dummyActivated             = ($Cactivated eq 'on') ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLREPORTS. ' SET uKey="' .$CuKey. '", periode="' .$Cperiode. '", timeperiodID="' .$CtimeperiodID. '", status="' .$dummyStatus. '", errorDetails="' .$dummyErrorDetails. '", bar="' .$dummyBar. '", hourlyAverage="' .$dummyHourlyAverage. '", dailyAverage="' .$dummyDailyAverage. '", showDetails="' .$dummyShowDetails. '", showComments="' .$dummyShowComments. '", showPerfdata="' .$dummyShowPerfdata. '", showTop20SlowTests="' .$dummyShowTop20SlowTests. '", printerFriendlyOutput="' .$dummyPrinterFriendlyOutput. '", formatOutput="' .$CformatOutput. '", userPassword="' .$CuserPassword.'", activated="' .$dummyActivated. '" WHERE id="' .$Cid. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All reports listed";

      $sql = "select SQL_NO_CACHE count(id) from $SERVERTABLREPORTS";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;orderBy=$orderBy");

      $sql = "select $SERVERTABLREPORTS.id, $SERVERTABLREPORTS.uKey, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), $SERVERTABLREPORTS.periode, $SERVERTABLTIMEPERIODS.timeperiodName, $SERVERTABLREPORTS.formatOutput, $SERVERTABLREPORTS.activated from $SERVERTABLREPORTS, $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT, $SERVERTABLTIMEPERIODS where $SERVERTABLREPORTS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLREPORTS.timeperiodID = $SERVERTABLTIMEPERIODS.timeperiodID and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Plugin Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=periode desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> When <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=periode asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=timeperiodName desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> SLA Window <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=timeperiodName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=formatOutput desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Format Output <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=formatOutput asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingReports, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Report', 'id', '0', '0|1', '3#N=>Never|D=>Daily|W=>Weekly|M=>Monthly|Q=>Quarterly|Y=>Yearly', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select id, uKey, periode, timeperiodID, status, errorDetails, bar, hourlyAverage, dailyAverage, showDetails, showComments, showPerfdata, showTop20SlowTests, printerFriendlyOutput, formatOutput, userPassword, activated from $SERVERTABLREPORTS where id = '$Cid'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($Cid, $CuKey, $Cperiode, $CtimeperiodID, $Cstatus, $CerrorDetails, $Cbar, $ChourlyAverage, $CdailyAverage, $CshowDetails, $CshowComments, $CshowPerfdata, $CshowTop20SlowTests, $CprinterFriendlyOutput, $CformatOutput, $CuserPassword, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $Cid                    = 'new' if ($action eq 'duplicateView');
        $Cstatus                = ($Cstatus == 1) ? 'on' : 'off';
        $CerrorDetails          = ($CerrorDetails == 1) ? 'on' : 'off';
        $Cbar                   = ($Cbar == 1) ? 'on' : 'off';
        $ChourlyAverage         = ($ChourlyAverage == 1) ? 'on' : 'off';
        $CdailyAverage          = ($CdailyAverage == 1) ? 'on' : 'off';
        $CshowDetails           = ($CshowDetails == 1) ? 'on' : 'off';
        $CshowComments          = ($CshowComments == 1) ? 'on' : 'off';
        $CshowPerfdata          = ($CshowPerfdata == 1) ? 'on' : 'off';
        $CshowTop20SlowTests    = ($CshowTop20SlowTests == 1) ? 'on' : 'off';
        $CprinterFriendlyOutput = ($CprinterFriendlyOutput == 1) ? 'on' : 'off';
        $Cactivated             = ($Cactivated == 1) ? 'on' : 'off';
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
    }

    if ($action eq 'insertView' or $action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'displayView' or $action eq 'editView') {
      if ($CuKey eq 'none' or $action eq 'insertView' or $action eq 'duplicateView' or $action eq 'editView') {
        $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
      } else {
        $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where uKey = '$CuKey' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment";
      }

      ($rv, $uKeySelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CuKey, 'uKey', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, "onload=\"javascript:enableDisableFields();\"", 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function enableDisableFields() {
  if ( document.reports.periode.value == 'Q' || document.reports.periode.value == 'Y' ) {
    document.reports.hourlyAverage.disabled=true;
    document.reports.hourlyAverage.checked=false;

    document.reports.dailyAverage.disabled=true;
    document.reports.dailyAverage.checked=false;
  } else {
    if ( document.reports.periode.value == 'M' ) {
      document.reports.hourlyAverage.disabled=true;
      document.reports.hourlyAverage.checked=false;

      document.reports.dailyAverage.disabled=false;
    } else {
      document.reports.hourlyAverage.disabled=false;
      document.reports.dailyAverage.disabled=false;
    }  
  }  
}

function validateForm() {
  if( document.reports.uKey.options[document.reports.uKey.selectedIndex].value == 'none' ) {
    document.reports.uKey.focus();
    alert('Please select one of the applications!');
    return false;
  }

  if ( document.reports.periode.value == null || document.reports.periode.value == 'none' ) {
    document.reports.periode.focus();
    alert('Please select Never, Daily, Weekly, Monthly, Quaterly or Yearly!');
    return false;
  }

  if ( document.reports.timeperiodID.value == null || document.reports.timeperiodID.value == 'none' ) {
    document.reports.timeperiodID.focus();
    alert('Please select one of the SLA windows!');
    return false;
  }

  if( document.reports.formatOutput.options[document.reports.formatOutput.selectedIndex].value == 'none' ) {
    document.reports.formatOutput.focus();
    alert('Please select one of the output formats!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="reports" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"reports\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print <<HTML;
  <input type="hidden" name="pagedir"    value="$pagedir">
  <input type="hidden" name="pageset"    value="$pageset">
  <input type="hidden" name="debug"      value="$debug">
  <input type="hidden" name="CGISESSID"  value="$sessionID">
  <input type="hidden" name="pageNo"     value="$pageNo">
  <input type="hidden" name="pageOffset" value="$pageOffset">
  <input type="hidden" name="action"     value="$nextAction">
  <input type="hidden" name="orderBy"    value="$orderBy">
HTML
    } else {
      print "<br>\n";
    }

    print "  <input type=\"hidden\" name=\"id\"   value=\"$Cid\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView' and $action ne "listView");

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert new report]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all reports]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $statusChecked                = ($Cstatus eq 'on') ? " checked" : '';
      my $errorDetailsChecked          = ($CerrorDetails eq 'on') ? " checked" : '';
      my $barChecked                   = ($Cbar eq 'on') ? " checked" : '';
      my $hourlyAverageChecked         = ($ChourlyAverage eq 'on') ? " checked" : '';
      my $dailyAverageChecked          = ($CdailyAverage eq 'on') ? " checked" : '';
      my $showDetailsChecked           = ($CshowDetails eq 'on') ? " checked" : '';
      my $showCommentsChecked          = ($CshowComments eq 'on') ? " checked" : '';
      my $showPerfdataChecked          = ($CshowPerfdata eq 'on') ? " checked" : '';
      my $showTop20SlowTestsChecked    = ($CshowTop20SlowTests eq 'on') ? " checked" : '';
      my $printerFriendlyOutputChecked = ($CprinterFriendlyOutput eq 'on') ? " checked" : '';
      my $activatedChecked             = ($Cactivated eq 'on') ? " checked" : '';

      my $formatPeriodeSelect = create_combobox_from_keys_and_values_pairs ('N=>Never|D=>Daily|W=>Weekly|M=>Monthly|Q=>Quarterly|Y=>Yearly', 'K', 0, $Cperiode, 'periode', 'none', '-Select-', $formDisabledAll, 'onChange="javascript:enableDisableFields();"', $debug);

      my $slaWindowSelect = '';
      ($rv, $slaWindowSelect, undef) = create_combobox_from_DBI ($rv, $dbh, "select timeperiodID, timeperiodName from $SERVERTABLTIMEPERIODS where activated = 1 order by timeperiodName", 1, '', $CtimeperiodID, 'timeperiodID', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      my $formatOutputSelect = create_combobox_from_keys_and_values_pairs ('pdf=>PDF', 'V', 0, $CformatOutput, 'formatOutput', 'none', '-Select-', $formDisabledAll, '', $debug);

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>ID: </b></td><td>
          <input type="text" name="id" value="$Cid" size="11" maxlength="11" $formDisabledPrimaryKey>
        </td></tr>
		<tr><td><b>Application: </b></td><td>
          $uKeySelect
        </td></tr>
		<tr><td><b>When: </b></td><td>
          $formatPeriodeSelect
        </td></tr>
		<tr><td><b>SLA Window: </b></td><td>
          $slaWindowSelect
        </td></tr>
		<tr><td>Status: </td><td>
          <input type="checkbox" name="status" $statusChecked $formDisabledAll>
        </td></tr>
		<tr><td>Error Details: </td><td>
          <input type="checkbox" name="errorDetails" $errorDetailsChecked $formDisabledAll>
        </td></tr>
		<tr><td>Bar: </td><td>
          <input type="checkbox" name="bar" $barChecked $formDisabledAll>
        </td></tr>
		<tr><td>Hourly Average: </td><td>
          <input type="checkbox" name="hourlyAverage" $hourlyAverageChecked $formDisabledAll>
        </td></tr>
		<tr><td>Daily Average: </td><td>
          <input type="checkbox" name="dailyAverage" $dailyAverageChecked $formDisabledAll>
        </td></tr>
		<tr><td>Show Details: </td><td>
          <input type="checkbox" name="showDetails" $showDetailsChecked $formDisabledAll>
        </td></tr>
		<tr><td>Show Comments: </td><td>
          <input type="checkbox" name="showComments" $showCommentsChecked $formDisabledAll>
        </td></tr>
		<tr><td>Show Performance Data: </td><td>
          <input type="checkbox" name="showPerfdata" $showPerfdataChecked $formDisabledAll>
        </td></tr>
		<tr><td>Show Top 20 Slow Tests: </td><td>
          <input type="checkbox" name="showTop20SlowTests" $showTop20SlowTestsChecked $formDisabledAll>
        </td></tr>
		<tr><td>Printer Friendly Output: </td><td>
          <input type="checkbox" name="printerFriendlyOutput" $printerFriendlyOutputChecked $formDisabledAll>
        </td></tr>
		<tr><td><b>Format Output: </b></td><td>
          $formatOutputSelect
        </td></tr>
		<tr><td><b>User Password: </b></td><td>
          <input type="password" name="userPassword" value="$CuserPassword" size="15" maxlength="15" $formDisabledAll>
        </td></tr>
        <tr><td>&nbsp;</td><td>This field contains the document user password, a string that is used by Adobe Acrobat to restrict viewing permissions on the file.<br>If this field is left blank, any user may view the document without entering a password.</td></tr>
HTML
      print <<HTML;
		<tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Report: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingReports</td></tr>" if (defined $matchingReports and $matchingReports ne '');
    } else {
      print "    <tr><td align=\"center\"><br>$matchingReports</td></tr>";
    }

    print "  </table>\n";

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
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

