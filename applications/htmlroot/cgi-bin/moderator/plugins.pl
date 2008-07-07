#!/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2008 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2008/mm/dd, v3.000.018, plugins.pl for ASNMTAP::Asnmtap::Applications::CGI
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

use ASNMTAP::Time v3.000.018;
use ASNMTAP::Time qw(&get_csvfiledate);

use ASNMTAP::Asnmtap::Applications::CGI v3.000.018;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR :DBREADWRITE :DBTABLES &sending_mail);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "plugins.pl";
my $prgtext     = "Plugins";
my $version     = do { my @r = (q$Revision: 3.000.018$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))            ? $cgi->param('pagedir')            : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))            ? $cgi->param('pageset')            : 'moderator';  $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))              ? $cgi->param('debug')              : 'F';
my $pageNo              = (defined $cgi->param('pageNo'))             ? $cgi->param('pageNo')             : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))         ? $cgi->param('pageOffset')         : 0;
my $orderBy             = (defined $cgi->param('orderBy'))            ? $cgi->param('orderBy')            : 'optionValueTitle';
my $action              = (defined $cgi->param('action'))             ? $cgi->param('action')             : 'listView';
my $CuKey               = (defined $cgi->param('uKey'))               ? $cgi->param('uKey')               : '';
my $CshortDescription   = (defined $cgi->param('shortDescription'))   ? $cgi->param('shortDescription')   : '';
my $Ctrendline          = (defined $cgi->param('trendline'))          ? $cgi->param('trendline')          : 0;
my $ChelpPluginTextname = (defined $cgi->param('helpPluginTextname')) ? $cgi->param('helpPluginTextname') : '<NIHIL>';
my $ChelpPluginFilename = (defined $cgi->param('helpPluginFilename')) ? $cgi->param('helpPluginFilename') : '<NIHIL>';
my $CholidayBundleID    = (defined $cgi->param('holidayBundleID'))    ? $cgi->param('holidayBundleID')    : 0;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledUniqueKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, $remoteUserLoggedOn, undef, undef, $givenNameLoggedOn, $familyNameLoggedOn, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Plugins", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&uKey=$CuKey&shortDescription=$CshortDescription&trendline=$Ctrendline&helpPluginTextname=$ChelpPluginTextname&helpPluginFilename=$ChelpPluginFilename&holidayBundleID=$CholidayBundleID";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>uKey              : $CuKey<br>shortDescription  : $CshortDescription<br>trendline         : $Ctrendline<br>helpPluginTextname: $ChelpPluginTextname<br>helpPluginFilename: $ChelpPluginFilename<br>holiday Bundle ID : $CholidayBundleID<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  if ( $ChelpPluginFilename eq '' or $ChelpPluginFilename eq '<NIHIL>' ) {
    $ChelpPluginFilename = ( $ChelpPluginTextname eq '' ? '<NIHIL>' : $ChelpPluginTextname );
    $ChelpPluginTextname = '';
  } else {
    if ( $cgi->param('helpPluginFilename') eq '' ) {
      $ChelpPluginFilename = $ChelpPluginTextname;
      $ChelpPluginTextname = '';
    } else {
      $ChelpPluginFilename =~ s/^.*(?:\/|\\)//;
      $ChelpPluginTextname = '<br><br>Help Plugin Filename: '. $ChelpPluginFilename;

      my $type = $cgi->uploadInfo( $cgi->param('helpPluginFilename') )->{'Content-Type'};

      if ( $type eq 'application/pdf') {
        my $fhOpen = open( FHOPEN, ">$PDPHELPPATH/$ChelpPluginFilename" );

        if ($fhOpen) {
          binmode FHOPEN;

          my $fh = $cgi->upload('helpPluginFilename');

          if ( defined $fh ) {
            while (<$fh>) { print FHOPEN; }
            $ChelpPluginTextname .= ', Uploaded and wrote file OK!';
          } else {
            $ChelpPluginTextname .= ', Cannot upload PDF file!';
          }

          close FHOPEN;
        } else {
          $ChelpPluginFilename = '<NIHIL>';
          $ChelpPluginTextname .= ', Cannot create PDF file!';
        }
      } else {
        $ChelpPluginFilename = '<NIHIL>';
        $ChelpPluginTextname .= ', PDF files only!';
      }
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my ($title, $environmentLabel, $holidayBundleSelect, $matchingPlugins, $navigationBar, $generatePluginCrontabSchedulingReport);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledUniqueKey = '';

    if ($action eq 'displayView') {
      $formDisabledUniqueKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display plugin $CuKey";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledUniqueKey = 'disabled';
      $htmlTitle    = "Update plugin $CuKey";
      $submitButton = "Update";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "Plugin $CuKey updated";

      $sql = "select concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), shortDescription, trendline, helpPluginFilename, holidayBundleID from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where uKey = '$CuKey' and $SERVERTABLPLUGINS.environment=$SERVERTABLENVIRONMENT.environment";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        my ($Otitle, $OshortDescription, $Otrendline, $OhelpPluginFilename, $OholidayBundleID) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

        $sql = 'UPDATE ' .$SERVERTABLPLUGINS. ' SET uKey="' .$CuKey. '", shortDescription="' .$CshortDescription. '", trendline="' .$Ctrendline. '", helpPluginFilename="' .$ChelpPluginFilename. '", holidayBundleID="' .$CholidayBundleID. '" WHERE uKey="' .$CuKey. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

        $matchingPlugins = "User               = $givenNameLoggedOn, $familyNameLoggedOn ($remoteUserLoggedOn)\n\nuKey               = $CuKey\n\ntitle              = $Otitle\n\nshortDescription old:\n$OshortDescription\n\nshortDescription new:\n$CshortDescription\n\ntrendline          = $Otrendline -> $Ctrendline\n\nhelpPluginTextname = $ChelpPluginTextname\n\nhelpPluginFilename = $OhelpPluginFilename -> $ChelpPluginFilename\n\nholidayBundleID    = $OholidayBundleID -> $CholidayBundleID";
        my $subject = "$htmlTitle regarding short description, trendline, holiday bundle and/or uploading plugindoc: ". get_csvfiledate();
        my $message = "Geachte, Cher,\n\n\n$matchingPlugins\n\n\n-- Moderator\n\n$APPLICATION\n$DEPARTMENT\n$BUSINESS\n";

        unless ( sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, 0 ) ) {
          print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
          print "<H1>MAIL Error:</H1>\nProblem sending email to the '$APPLICATION' server administrators\n<BR>\n";
        }
      }

      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All plugins listed";

      $sql = "select SQL_NO_CACHE count(uKey) from $SERVERTABLPLUGINS";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;orderBy=$orderBy");

      $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle, $SERVERTABLPLUGINS.environment, activated from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header  = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Unique Key <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=optionValueTitle desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=optionValueTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=environment desc, optionValueTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Environment <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=environment asc, optionValueTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, uKey desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>\n";
      ($rv, $matchingPlugins, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Plugin', 'uKey', '0', '', '', '', $orderBy, $header, $navigationBar, 0, 0, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'displayView' or $action eq 'editView') {
      $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), $SERVERTABLENVIRONMENT.label, shortDescription, trendline, helpPluginFilename, holidayBundleID from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where uKey = '$CuKey' and $SERVERTABLPLUGINS.environment=$SERVERTABLENVIRONMENT.environment";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CuKey, $title, $environmentLabel, $CshortDescription, $Ctrendline, $ChelpPluginFilename, $CholidayBundleID) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $sql = "select holidayBundleID, holidayBundleName from $SERVERTABLHOLIDYSBNDL where activated = '1' order by holidayBundleName";
      ($rv, $holidayBundleSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CholidayBundleID, 'holidayBundleID', '0', '+ No Holiday Bundle', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $generatePluginCrontabSchedulingReport = 1;
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'editView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
  if ( document.plugins.title.value == null || document.plugins.title.value == '' ) {
    document.plugins.title.focus();
    alert('Please enter a title!');
    return false;
  }

  if ( document.plugins.trendline.value == null || document.plugins.trendline.value == '' ) {
    document.plugins.trendline.focus();
    alert('Please enter a trendline!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="plugins" enctype="multipart/form-data" onSubmit="return validateForm();">
HTML
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq 'editView') {
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

    print "  <input type=\"hidden\" name=\"uKey\"   value=\"$CuKey\">\n" if ($formDisabledUniqueKey ne '' and $action ne 'displayView');
	
    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all plugins]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq 'displayView' or $action eq 'editView') {
      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
      <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Unique Key: </b></td><td>
          <input type="text" name="uKey" value="$CuKey" size="11" maxlength="11" $formDisabledUniqueKey>
        <tr><td><b>Title: </b></td><td>
          <input type="text" name="title" value="$title" size="75" maxlength="75" disabled>
        <tr><td valign="top"><b>Short Description: </b></td><td>
          <textarea cols="75" rows="10" name="shortDescription" $formDisabledAll>$CshortDescription</textarea>
        <tr><td><b>Environment: </b></td><td>
          <input type="text" name="environment" value="$environmentLabel" size="16" disabled>
        <tr><td><b>Trendline: </b></td><td>
          <input type="text" name="trendline" value="$Ctrendline" size="6" maxlength="6" $formDisabledAll>
        <tr><td valign="top">Help Plugin Filename: </td><td>
          <input type="text" name="helpPluginTextname" value="$ChelpPluginFilename" size="100" maxlength="100" $formDisabledAll><br>
          <input type="file" name="helpPluginFilename" size="100" accept="application/pdf" $formDisabledAll>
        <tr><td>Holiday Bundle: </td><td>
    	  $holidayBundleSelect
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'editView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'edit') {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle$ChelpPluginTextname</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingPlugins</td></tr>" if (defined $matchingPlugins and $matchingPlugins ne '');
    } else {
      print "    <tr><td align=\"center\"><br>$matchingPlugins</td></tr>";
    }

    print "  </table>\n";

    if ($action eq 'editView') {
      print "</form>\n";
    } else {
      print "<br>\n";
    }

    print "<table align=\"center\">\n<tr><td>\n<img src=\"$HTTPSURL/cgi-bin/moderator/generatePluginCrontabSchedulingReport.pl?uKey=$CuKey&amp;".encode_html_entities('U', "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID")."\"></td></tr></table><br>\n" if (defined $generatePluginCrontabSchedulingReport);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
