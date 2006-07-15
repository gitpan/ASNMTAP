#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# � Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/07/15, v3.000.010, trendlineCorrectionReports.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.000.010;
use ASNMTAP::Time qw(&get_epoch);

use ASNMTAP::Asnmtap::Applications::CGI v3.000.010;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "trendlineCorrectionReports.pl";
my $prgtext     = "Trendline Correction Reports (for the Collector)";
my $version     = '3.000.010';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir    = (defined $cgi->param('pagedir'))   ? $cgi->param('pagedir')   : '<NIHIL>';   $pagedir =~ s/\+/ /g;
my $pageset    = (defined $cgi->param('pageset'))   ? $cgi->param('pageset')   : "moderator"; $pageset =~ s/\+/ /g;
my $debug      = (defined $cgi->param('debug'))     ? $cgi->param('debug')     : "F";
my $action     = (defined $cgi->param('action'))    ? $cgi->param('action')    : "listView";
my $CsessionID = (defined $cgi->param('sessionID')) ? $cgi->param('sessionID') : "";

my $shortlist  = (defined $cgi->param('shortlist')) ? $cgi->param('shortlist') : "0";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($nextAction, $matchingTrendlineCorrections);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Trendlines", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&sessionID=$CsessionID";

# Debug information
print "<pre>pagedir     : $pagedir<br>pageset     : $pageset<br>debug       : $debug<br>CGISESSID   : $sessionID<br>action      : $action<br>session ID  : $CsessionID<br>URL ...     : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($matchingSessionDetails, $matchingSessionsBlocked, $matchingSessionsActive, $matchingSessionsExpired, $matchingSessionsEmpty, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

  if ($action eq "listView") {
    $htmlTitle = "Trendline Correction Reports";

    my ($rv, $dbh, $sth, $sql);
    $rv = 1;

    # open connection to database and query data
    $dbh = DBI->connect("DBI:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);

    if ( $dbh and $rv ) {
      my $startDateEpoch = get_epoch ('-14 days');
      my $startDate = sprintf ( "%04d-%02d-%02d", (localtime($startDateEpoch))[5]+1900, (localtime($startDateEpoch))[4]+1, (localtime($startDateEpoch))[3] );

      my $yesterdayEpoch = get_epoch ('yesterday');
      my $yesterday = sprintf ( "%04d-%02d-%02d", (localtime($yesterdayEpoch))[5]+1900, (localtime($yesterdayEpoch))[4]+1, (localtime($yesterdayEpoch))[3] );

      my $actionPressend = ($iconDetails or $iconEdit) ? 1 : 0;
      my $actionHeader = ($actionPressend) ? "<th>Action</th>" : '';
      my $colspan = 9 + $actionPressend;
      my $header = "<tr><th> Title </th><th> uKey </th><th> Trendline </th><th> - </th><th> Average </th><th> % </th><th> + </th><th> % </th><th> Proposal </th>$actionHeader</tr>\n";

      my ($uKey, $title, $test, $resultsdir, $trendline, $percentage, $tolerance, $hour, $calculated);

      $sql = "select $SERVERTABLPLUGINS.uKey, $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.test, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLPLUGINS.trendline, $SERVERTABLPLUGINS.percentage, $SERVERTABLPLUGINS.tolerance, hour($SERVERTABLEVENTS.startTime) as hour, round(avg($SERVERTABLEVENTS.duration), 2) from $SERVERTABLPLUGINS, $SERVERTABLEVENTS force index (key_startDate) where $SERVERTABLPLUGINS.trendline <> 0 and $SERVERTABLPLUGINS.uKey = $SERVERTABLEVENTS.uKey and ($SERVERTABLEVENTS.startDate between '$startDate' and '$yesterday') and hour($SERVERTABLEVENTS.startTime) between 9 and 17 and $SERVERTABLEVENTS.status = 'OK' group by $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.uKey, hour";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$uKey, \$title, \$test, \$resultsdir, \$trendline, \$percentage, \$tolerance, \$hour, \$calculated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;

      $matchingTrendlineCorrections .= '<table width="100%" border="0" cellspacing="1" cellpadding="1" bgcolor="'. $COLORSTABLE{TABLE} .'"><tr><th align="center" colspan="'. $colspan .'"> Trendline > 0 </th></tr>'. $header;

      if ( $rv ) {
        sub matchingTrendlineCorrections {
          my ($uKey, $title, $test, $resultsdir, $trendline, $percentage, $tolerance, $calculated) = @_;

          use POSIX qw(ceil floor);

          my ($calculatedMIN, $calculatedMAX, $calculatedNEW, $ActionItem);
          $calculated = sprintf("%.2f", $calculated * ( 100 + $percentage ) / 100 );

          if ( $tolerance ) {
            $calculatedMIN = sprintf("%.2f", $calculated * ( 100 - $tolerance  ) / 100 );
            $calculatedMAX = sprintf("%.2f", $calculated * ( 100 + $tolerance  ) / 100 );

            $calculatedNEW = $trendline >= $calculatedMIN & $trendline <= $calculatedMAX ? 0 : ( $calculatedMAX > $trendline ? ceil( $calculatedMAX ) : ( floor( ($calculatedMAX + $trendline) / 2 ) < $calculatedMAX ? ceil( ($calculatedMAX + $trendline) / 2 ) : floor( ($calculatedMAX + $trendline) / 2 ) ) );
            $calculatedNEW = '' if ( $calculatedNEW == 0 or $calculatedNEW == $trendline );
          } else {
            $calculatedMIN = $calculatedMAX = $calculatedNEW = '';
          }

          $ActionItem = ( $actionPressend and $calculatedNEW ? 1 : '' );

          if ( $ActionItem or ! $shortlist ) {
            $test =~ s/\.pl//g;
            $ActionItem  = "&nbsp;<A HREF=\"#\" onclick=\"openPngImage('/results/$resultsdir/$test-$uKey-sql.html',912,576,null,null,'Trendline',10,false,'Trendline');\"><img src=\"$IMAGESURL/$ICONSRECORD{table}\" title=\"Trendline MRTG Chart\" alt=\"Trendline MRTG Chart\" border=\"0\"></A>&nbsp;";
            $ActionItem .= "<A HREF=\"#\" onclick=\"openPngImage('/cgi-bin/generateChart.pl?$urlAccessParameters&detailed=on&uKey1=$uKey&uKey2=none&uKey3=none&startDate=$yesterday&endDate=$startDate&inputType=fromto&chart=Bar',1016,400,null,null,'Bar',10,false,'Bar');\"><img src=\"$IMAGESURL/$ICONSRECORD{table}\" title=\"Trendline Bar Chart\" alt=\"Trendline Bar Chart\" border=\"0\"></A>&nbsp;";

            if ( $userType >= 4 ) {
              $ActionItem .= "&nbsp;<A HREF=\"#\" onclick=\"openPngImage('/cgi-bin/sadmin/plugins.pl?$urlAccessParameters&action=editView&uKey=$uKey&orderBy=uKey',1016,760,null,null,'Edit',10,false,'Edit');\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Trendline\" alt=\"Edit Trendline\" border=\"0\"></A>&nbsp;";

              if ( $calculatedNEW ) {
                $ActionItem .= "<A HREF=\"#\">";
                $ActionItem .= ( $calculatedNEW > $trendline ? "<IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" title=\"Update Trendline\" ALT=\"Update Trendline\" BORDER=0>" : "<IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" title=\"Update Trendline\" ALT=\"Update Trendline\" BORDER=0>" );
                $ActionItem .= "<img src=\"$IMAGESURL/$ICONSRECORD{query}\" title=\"Update Trendline\" alt=\"Update Trendline\" border=\"0\"></A>&nbsp;";
              }
            }

            $matchingTrendlineCorrections .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$title</td><td>$uKey</td><td align=\"right\" bgcolor=\"#0F0F0F\">&nbsp;$trendline&nbsp;</td><td align=\"right\" bgcolor=\"#335566\">&nbsp;$calculatedMIN&nbsp;</td><td align=\"right\" bgcolor=\"#0F0F0F\">&nbsp;$calculated&nbsp;</td><td align=\"right\" bgcolor=\"#0F0F0F\">&nbsp;$percentage&nbsp;</td><td align=\"right\" bgcolor=\"#335566\">&nbsp;$calculatedMAX&nbsp;</td><td align=\"right\" bgcolor=\"#335566\">&nbsp;$tolerance&nbsp;</td><td align=\"right\" bgcolor=\"#000000\">&nbsp;<b>$calculatedNEW</b>&nbsp;</td><td bgcolor=\"#335566\">$ActionItem</td></tr>\n";
          }
        }

        my ($groupEND, $groupMAX, $uKeyPREV, $titlePREV, $testPREV, $resultsdirPREV, $trendlinePREV, $percentagePREV, $tolerancePREV) = (0, 0, 0, 0, 0, 25, 5);

        while( $sth->fetch() ) {
          $groupEND = ($uKeyPREV ne '0' and $uKeyPREV ne $uKey ? 1 : 0);

          if ( $groupEND ) {
            matchingTrendlineCorrections ($uKeyPREV, $titlePREV, $testPREV, $resultsdirPREV, $trendlinePREV, $percentagePREV, $tolerancePREV, $groupMAX);
            $groupMAX = $calculated;
          } else {
            $groupMAX = $calculated > $groupMAX ? $calculated : $groupMAX;
          }

          $uKeyPREV       = $uKey;
          $titlePREV      = $title;
          $testPREV       = $test;
          $resultsdirPREV = $resultsdir;
          $trendlinePREV  = $trendline;
          $percentagePREV = $percentage;
		  $tolerancePREV  = $tolerance;
        }

        matchingTrendlineCorrections ($uKeyPREV, $titlePREV, $testPREV, $resultsdirPREV, $trendlinePREV, $percentagePREV, $tolerancePREV, $groupMAX);

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
      }

      unless ( $shortlist ) {
        $sql = "select $SERVERTABLPLUGINS.uKey, $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.test, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLPLUGINS.trendline, $SERVERTABLPLUGINS.percentage, $SERVERTABLPLUGINS.tolerance, round(avg($SERVERTABLEVENTS.duration), 2) from $SERVERTABLPLUGINS, $SERVERTABLEVENTS where $SERVERTABLPLUGINS.trendline = 0 and $SERVERTABLPLUGINS.uKey = $SERVERTABLEVENTS.uKey group by $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.uKey";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;
        $sth->bind_columns( \$uKey, \$title, \$test, \$resultsdir, \$trendline, \$percentage, \$tolerance, \$calculated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;

        $matchingTrendlineCorrections .= '<tr><td '. $colspan .'">&nbsp</th></tr><tr><th align="center" colspan="'. $colspan .'"> Trendline = 0 </th></tr>'. $header;

        if ( $rv ) {
          while( $sth->fetch() ) {
            matchingTrendlineCorrections ($uKey, $title, $test, $resultsdir, $trendline, $percentage, $tolerance, $calculated);
          }

          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
        }
      }

      $matchingTrendlineCorrections .= '</table>';
      $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
    }

    $nextAction = "listView";
  }

  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'T', '', $sessionID);

  print "<br>\n";

  print <<HTML;
  <table border="0" cellspacing="0" cellpadding="0" align="center">
    <tr align="center"><td>$matchingTrendlineCorrections</td></tr>
  </table>
HTML

  print "<br>\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -