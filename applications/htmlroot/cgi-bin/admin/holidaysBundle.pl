#!/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2008 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2008/mm/dd, v3.000.017, holidaysBundle.pl for ASNMTAP::Asnmtap::Applications::CGI
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

use ASNMTAP::Asnmtap::Applications::CGI v3.000.017;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :ADMIN :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "holidaysBundle.pl";
my $prgtext     = "Holidays Bundle";
my $version     = do { my @r = (q$Revision: 3.000.017$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir            = (defined $cgi->param('pagedir'))           ? $cgi->param('pagedir')           : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset            = (defined $cgi->param('pageset'))           ? $cgi->param('pageset')           : 'admin';   $pageset =~ s/\+/ /g;
my $debug              = (defined $cgi->param('debug'))             ? $cgi->param('debug')             : 'F';
my $pageNo             = (defined $cgi->param('pageNo'))            ? $cgi->param('pageNo')            : 1;
my $pageOffset         = (defined $cgi->param('pageOffset'))        ? $cgi->param('pageOffset')        : 0;
my $orderBy            = (defined $cgi->param('orderBy'))           ? $cgi->param('orderBy')           : 'holidayBundleName asc';
my $action             = (defined $cgi->param('action'))            ? $cgi->param('action')            : 'listView';
my $CholidayBundleID   = (defined $cgi->param('holidayBundleID'))   ? $cgi->param('holidayBundleID')   : 'new';
my $CholidayBundleName = (defined $cgi->param('holidayBundleName')) ? $cgi->param('holidayBundleName') : '';
my $CcountryIDreload   = (defined $cgi->param('countryIDreload'))   ? $cgi->param('countryIDreload')   : 0;
my $CcountryID         = (defined $cgi->param('countryID'))         ? $cgi->param('countryID')         : 'none';
my @CholidayID         =          $cgi->param('holidayID');
my $Cactivated         = (defined $cgi->param('activated'))         ? $cgi->param('activated')         : 'off';

my $CholidayID = (@CholidayID) ? '/'. join ('/', @CholidayID) .'/' : '';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledNoCountryID, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Holidays Bundle", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&holidayBundleID=$CholidayBundleID&holidayBundleName=$CholidayBundleName&countryIDreload=$CcountryIDreload&countryID=$CcountryID&holidayID=$CholidayID&activated=$Cactivated";

# Debug information
print "<pre>pagedir            : $pagedir<br>pageset            : $pageset<br>debug              : $debug<br>CGISESSID          : $sessionID<br>page no            : $pageNo<br>page offset        : $pageOffset<br>order by           : $orderBy<br>action             : $action<br>holiday Bundle ID  : $CholidayBundleID<br>holiday Bundle Name: $CholidayBundleName<br>countryID reload   : $CcountryIDreload<br>countryID          : $CcountryID<br>holidayID          : $CholidayID<br>activated          : $Cactivated<br>URL ...            : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($countryIDSelect, $holidaysSelect, $matchingHolidaysBundle, $matchingPlugins, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledNoCountryID = $formDisabledPrimaryKey = '';

    if ($CcountryIDreload) {
      if ($action eq 'insert' or $action eq 'insertView') {
        $action = "insertView";
      } elsif ($action eq 'edit' or $action eq 'editView') {
        $action = "editView";
      } else {
        $action = "listView";
      }
    }

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Insert Holiday Bundle";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Holiday Bundle $CholidayBundleID exist before to insert";

      $sql = "select holidayBundleID from $SERVERTABLHOLIDYSBNDL WHERE holidayBundleID = '$CholidayBundleID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Holiday Bundle $CholidayBundleID exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Holiday Bundle $CholidayBundleID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLHOLIDYSBNDL. ' SET holidayBundleName="' .$CholidayBundleName. '", holidayID="' .$CholidayID. '", countryID="' .$CcountryID. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledAll = $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Delete Holiday Bundle $CholidayBundleID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select uKey, test from $SERVERTABLPLUGINS where holidayBundleID = '$CholidayBundleID' order by holidayBundleID";
      ($rv, $matchingHolidaysBundle) = check_record_exist ($rv, $dbh, $sql, 'Plugins', 'Unique Key', 'Title', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
	  
	  if ($matchingHolidaysBundle eq '') {
        $sql = 'DELETE FROM ' .$SERVERTABLHOLIDYSBNDL. ' WHERE holidayBundleID="' .$CholidayBundleID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
        $htmlTitle = "Holiday Bundle $CholidayBundleID deleted";
      } else {
        $htmlTitle = "Holiday Bundle $CholidayBundleID not deleted, still used by";
      }
    } elsif ($action eq 'displayView') {
      $formDisabledAll = $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Display Holiday Bundle $CholidayBundleID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit Holiday Bundle $CholidayBundleID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $matchingHolidaysBundle = '';
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;

      unless ( $dummyActivated ) {
        $sql = "select uKey, test from $SERVERTABLPLUGINS where holidayBundleID = '$CholidayBundleID' order by holidayBundleID";
        ($rv, $matchingHolidaysBundle) = check_record_exist ($rv, $dbh, $sql, 'Plugins', 'Unique Key', 'Title', $matchingHolidaysBundle, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      }

	  if ($dummyActivated or $matchingHolidaysBundle eq '') {
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'UPDATE ' .$SERVERTABLHOLIDYSBNDL. ' SET holidayBundleID="' .$CholidayBundleID. '", holidayBundleName="' .$CholidayBundleName. '", holidayID="' .$CholidayID. '", countryID="' .$CcountryID. '", activated="' .$dummyActivated. '" WHERE holidayBundleID="' .$CholidayBundleID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
        $htmlTitle    = "Holiday Bundle $CholidayBundleID updated";
      } else {
        $htmlTitle    = "Holiday Bundle $CholidayBundleID not deactivated and updated, still used by";
      }
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All holiday bundles listed";

      $sql = "select SQL_NO_CACHE count(holidayBundleID) from $SERVERTABLHOLIDYSBNDL";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;orderBy=$orderBy");
 
      $sql = "select $SERVERTABLHOLIDYSBNDL.holidayBundleID, $SERVERTABLHOLIDYSBNDL.holidayBundleName, $SERVERTABLHOLIDYSBNDL.activated from $SERVERTABLHOLIDYSBNDL order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=holidayBundleName desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Holiday Bundle Name  <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=holidayBundleName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, holidayBundleName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, holidayBundleName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingHolidaysBundle, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Holiday Bundle', 'holidayBundleID', '0', '0', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if (!$CcountryIDreload and ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView')) {
      $sql = "select holidayBundleID, holidayBundleName, holidayID, countryID, activated from $SERVERTABLHOLIDYSBNDL where holidayBundleID = '$CholidayBundleID'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CholidayBundleID, $CholidayBundleName, $CholidayID, $CcountryID, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $CholidayBundleID = 'new' if ($action eq 'duplicateView');
        $Cactivated = ($Cactivated == 1) ? 'on' : 'off';
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      $sql = "select countryID, countryName from $SERVERTABLCOUNTRIES where activated = '1' order by countryName";
      ($rv, $countryIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcountryID, 'countryID', 'none', '-Select-', $formDisabledAll, 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      if ( $CcountryID ne 'none' ) {
        $sql = "select holidayID, holiday from $SERVERTABLHOLIDYS where countryID = '$CcountryID' or countryID = '00' order by holiday";
       ($rv, $holidaysSelect) = create_combobox_multiple_from_DBI ($rv, $dbh, $sql, $action, $CholidayID, 'holidayID', 'Country missing', 20, 64, $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
        $formDisabledNoCountryID = '';
      } else {
        $holidaysSelect = "Country missing";
        $formDisabledNoCountryID = 'disabled';
      }
    }

    if (!$CcountryIDreload and ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'editView')) {
      $matchingPlugins .= "<table border=0 cellpadding=1 cellspacing=1 bgcolor=\"$COLORSTABLE{TABLE}\"><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><th colspan=\"4\">Plugins:</th></tr><tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Primary Key</td><td>Title</td><td>Status</td><td>Action</td></tr>";
      my ($uKey, $title, $activated, $urlWithAccessParametersAction, $actionItem, $notActivated);
      $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle, activated from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where holidayBundleID = '$CholidayBundleID' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$uKey, \$title, \$activated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            $urlWithAccessParametersAction = "../sadmin/plugins.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;uKey=$uKey&amp;orderBy=uKey&amp;action";
            $actionItem = "&nbsp;";
         	$actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display View\" alt=\"Display View\" border=\"0\"></a>&nbsp;" if ($iconDetails);
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit View\" alt=\"Edit View\" border=\"0\"></a>&nbsp;" if ($iconEdit);
            $notActivated = ($activated) ? '' : ' not';
            $matchingPlugins .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$uKey</td><td>$title</td><td><b>$notActivated activated</b></td><td>$actionItem</td></tr>\n";
          }
        } else {
          $matchingPlugins .= "<tr><td>No records found</td></tr>\n";
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingPlugins .= "</table>\n";
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  if ( document.holidaysBundle.holidayBundleName.value == null || document.holidaysBundle.holidayBundleName.value == '' ) {
    document.holidaysBundle.holidayBundleName.focus();
    alert('Please enter a holiday bundle name!');
    return false;
  }

  if ( document.holidaysBundle.countryID.value == null || document.holidaysBundle.countryID.value == 'none' ) {
    document.holidaysBundle.countryID.focus();
    alert('Please select a country!');
    return false;
  }

  document.holidaysBundle.countryIDreload.value = 1;
  document.holidaysBundle.submit();
  return true;
}

function validateForm() {
  if ( document.holidaysBundle.holidayBundleName.value == null || document.holidaysBundle.holidayBundleName.value == '' ) {
    document.holidaysBundle.holidayBundleName.focus();
    alert('Please enter a holiday bundle name!');
    return false;
  }

  if ( document.holidaysBundle.countryID.value == null || document.holidaysBundle.countryID.value == 'none' ) {
    document.holidaysBundle.countryID.focus();
    alert('Please select a country!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="holidaysBundle" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"holidaysBundle\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print <<HTML;
  <input type="hidden" name="pagedir"         value="$pagedir">
  <input type="hidden" name="pageset"         value="$pageset">
  <input type="hidden" name="debug"           value="$debug">
  <input type="hidden" name="CGISESSID"       value="$sessionID">
  <input type="hidden" name="pageNo"          value="$pageNo">
  <input type="hidden" name="pageOffset"      value="$pageOffset">
  <input type="hidden" name="action"          value="$nextAction">
  <input type="hidden" name="orderBy"         value="$orderBy">
  <input type="hidden" name="countryIDreload" value="0">
HTML
    } else {
      print "<br>\n";
    }

    print "  <input type=\"hidden\" name=\"holidayBundleID\" value=\"$CholidayBundleID\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView');

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert new holiday bundle]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all holiday bundles]</a></td>
	  </tr></table>
    </td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $activatedChecked = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Holiday Bundle ID: </b></td><td>
          <input type="text" name="holidayBundleID" value="$CholidayBundleID" size="11" maxlength="11" $formDisabledPrimaryKey>
        </td></tr>
		<tr><td><b>Holiday Bundle Name: </b></td><td>
          <input type="text" name="holidayBundleName" value="$CholidayBundleName" size="64" maxlength="64" $formDisabledAll>
        </td></tr>
		<tr><td><b>Country: </b></td><td>
          $countryIDSelect
        </td></tr>
		<tr><td><b>Holidays: </b></td><td>
          $holidaysSelect
        </td></tr>
		<tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Holiday Bundle: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingHolidaysBundle</td></tr>" if (defined $matchingHolidaysBundle and $matchingHolidaysBundle ne '');
    } else {
      print "    <tr><td align=\"center\"><br>$matchingHolidaysBundle</td></tr>";
    }

    print "  </table>\n";

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print "</form>\n";
    } else {
      print "<br>\n";
    }

    print "<table align=\"center\">\n<tr><td>\n$matchingPlugins</td></tr></table><br>\n" if (defined $matchingPlugins);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

