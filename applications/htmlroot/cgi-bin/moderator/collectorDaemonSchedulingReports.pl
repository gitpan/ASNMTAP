#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# � Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/09/16, v3.000.011, collectorDaemonSchedulingReports.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.011;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR :REPORTS :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "collectorDaemonSchedulingReports.pl";
my $prgtext     = "Collector Daemon Scheduling Reports";
my $version     = '3.000.011';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1]);
my $currentSec = 0;

# URL Access Parameters
my $cgi = new CGI;
my $pagedir         = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : "index";    $pagedir =~ s/\+/ /g;
my $pageset         = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : "index-cv"; $pageset =~ s/\+/ /g;
my $debug           = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : "F";
my $sqlEndDate      = (defined $cgi->param('sqlEndDate'))      ? $cgi->param('sqlEndDate')      : timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);
my $sqlPeriode      = (defined $cgi->param('sqlPeriode'))      ? $cgi->param('sqlPeriode')      : 3600;
my $width           = (defined $cgi->param('width'))           ? $cgi->param('width')           : 1000;
my $xOffset         = (defined $cgi->param('xOffset'))         ? $cgi->param('xOffset')         : 300;
my $yOffset         = (defined $cgi->param('yOffset'))         ? $cgi->param('yOffset')         : 42;
my $labelOffset     = (defined $cgi->param('labelOffset'))     ? $cgi->param('labelOffset')     : 32;
my $AreaBOffset     = (defined $cgi->param('AreaBOffset'))     ? $cgi->param('AreaBOffset')     : 78;
my $hightMin        = (defined $cgi->param('hightMin'))        ? $cgi->param('hightMin')        : 195;
my $currentTimeslot = (defined $cgi->param('currentTimeslot')) ? $cgi->param('currentTimeslot') : "off";
my $pf              = (defined $cgi->param('pf'))              ? $cgi->param('pf')              : "off";
my $htmlToPdf       = (defined $cgi->param('htmlToPdf'))       ? $cgi->param('htmlToPdf')       : 0;

my $htmlTitle       = $prgtext;

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Daemons", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&sqlEndDate=$sqlEndDate&sqlPeriode=$sqlPeriode&width=$width&xOffset=$xOffset&yOffset=$yOffset&labelOffset=$labelOffset&AreaBOffset=$AreaBOffset&hightMin=$hightMin&currentTimeslot=$currentTimeslot&pf=$pf&htmlToPdf=$htmlToPdf";

# Debug information
print "<pre>pagedir    : $pagedir<br>pageset    : $pageset<br>debug      : $debug<br>CGISESSID  : $sessionID<br>sqlEndDate : $sqlEndDate<br>sqlPeriode : $sqlPeriode<br>width      : $width<br>xOffset    : $xOffset<br>yOffset    : $yOffset<br>labelOffset: $labelOffset<br>AreaBOffset: $AreaBOffset<br>hightMin   : $hightMin<br>pf         : $pf<br>htmlToPdf  : $htmlToPdf<br>URL ...    : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  my ($rv, $dbh, $sth, $sql, $errorMessage);
  my @collectorDaemons = ();

  # open connection to database and query data
  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);

  if ( $dbh and $rv ) {
    my $collectorDaemon;
    $sql = "select distinct $SERVERTABLCLLCTRDMNS.collectorDaemon from $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS where $SERVERTABLCLLCTRDMNS.activated = 1 and $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon and $SERVERTABLCRONTABS.activated = 1 order by $SERVERTABLCLLCTRDMNS.collectorDaemon";
    $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
    $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;
    $sth->bind_columns( \$collectorDaemon ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;

    if ( $rv ) {
      if ( $sth->rows ) {
        while( $sth->fetch() ) { push (@collectorDaemons, $collectorDaemon); }
      } else {
        $errorMessage .= "<br>There are no Collector Daemons available<br>\n";
      }

      $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
    }

    # Close database connection - - - - - - - - - - - - - - - - - - - - -
    $dbh->disconnect or $rv = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', -1, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if ($htmlToPdf) {
      print <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>
<head>
  <title>$htmlTitle</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/asnmtap.css">
</head>
<BODY>
<H1>$DEPARTMENT \@ $BUSINESS: '$APPLICATION' $prgtext</H1>
EndOfHtml
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', '', $sessionID);

      my $dummy = ($currentTimeslot eq "on") ? " checked" : "";
      my $currentTimeslotOutputBox = "<input type=\"checkbox\" name=\"currentTimeslot\"$dummy>Endpoint used from latest timeslot\n";

      $dummy = ($pf eq "on") ? " checked" : "";
      my $printerFriendlyOutputBox = "<input type=\"checkbox\" name=\"pf\"$dummy> Printer friendly output\n";

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
  var objectRegularExpressionSqlPeriode = /\^(12|24|36|48|60|72|84|94)00\$/;

  if ( document.daemons.sqlPeriode.value == null || document.daemons.sqlPeriode.value == '' ) {
    document.daemons.sqlPeriode.focus();
    alert('Please enter Periode!');
    return false;
  } else {
    if ( ! objectRegularExpressionSqlPeriode.test(document.daemons.sqlPeriode.value) ) {
      document.daemons.sqlPeriode.focus();
      alert('Please re-enter Periode (1200|2400|3600|4800|6000|7200|8400|9400): Bad Periode value!');
      return false;
    }
  }

  var objectRegularExpressionWidth = /\^(1[0-9][0-9][0-9])\$/;

  if ( document.daemons.width.value == null || document.daemons.width.value == '' ) {
    document.daemons.width.focus();
    alert('Please enter Width!');
    return false;
  } else {
    if ( ! objectRegularExpressionWidth.test(document.daemons.width.value) ) {
      document.daemons.width.focus();
      alert('Please re-enter Width  (1000-1999): Bad Width value!');
      return false;
    }
  }

  var objectRegularExpressionXoffset = /\^([1-3][0-9][0-9])\$/;
  
  if ( document.daemons.xOffset.value == null || document.daemons.xOffset.value == '' ) {
    document.daemons.xOffset.focus();
    alert('Please enter x Offset!');
    return false;
  } else {
    if ( ! objectRegularExpressionXoffset.test(document.daemons.xOffset.value) ) {
      document.daemons.xOffset.focus();
      alert('Please re-enter x Offset (100-399): Bad x Offset value !');
      return false;
    }
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="daemons" onSubmit="return validateForm();">
  <input type="hidden" name="pagedir"   value="$pagedir">
  <input type="hidden" name="pageset"   value="$pageset">
  <input type="hidden" name="debug"     value="$debug">
  <input type="hidden" name="CGISESSID" value="$sessionID">
  <table border="0">
    <tr align="left">
      <td>Periode:</td><td><input name="sqlPeriode" type="text" value="$sqlPeriode" size="4" maxlength="4">&nbsp;&nbsp;&nbsp;</td>
      <td>Width:</td><td><input name="width" type="text" value="$width" size="4" maxlength="4">&nbsp;&nbsp;&nbsp;</td>
      <td>x offset:</td><td><input name="xOffset" type="text" value="$xOffset" size="3" maxlength="3"></td>
    </tr>
    <tr align="left"><td>Options:</td><td colspan="5">$currentTimeslotOutputBox&nbsp;&nbsp;&nbsp;$printerFriendlyOutputBox</td></tr>
    <tr align="left"><td align="right"><br>
      <input type="submit" value="Scheduling"></td><td colspan="5"><br><input type="reset" value="Reset">
    </td></tr>
  </table>
</form>
<hr>
HTML
    }

    if (defined $errorMessage) {
      print $errorMessage, "\n" ;
    } else {
      foreach my $collectorDaemon (@collectorDaemons) {
        print "<br><center><img src=\"/cgi-bin/moderator/generateCollectorDaemonSchedulingReport.pl?collectorDaemon=$collectorDaemon&amp;".encode_html_entities('U', $urlAccessParameters)."\"></center>\n";
      }

      print "<br><center><a href=\"/cgi-bin/htmlToPdf.pl?HTMLtoPDFprg=$HTMLTOPDFPRG&amp;HTMLtoPDFhow=$HTMLTOPDFHOW&amp;scriptname=", $ENV{SCRIPT_NAME}, "&amp;",encode_html_entities('U', $urlAccessParameters),"\" target=\"_blank\">[Generate PDF file]</a></center>\n" if ((! defined $errorMessage) and ($HTMLTOPDFPRG ne '<nihil>' and $HTMLTOPDFHOW ne '<nihil>') and (! $htmlToPdf));
    }

    print '<BR>', "\n";
  } 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
