#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/09/16, v3.000.011, detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Time::Local;
use Date::Calc qw(Add_Delta_Days Delta_DHMS Week_of_Year);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.011;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :REPORTS :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl";
my $prgtext     = "Detailed Statistics, Report Generation And Compare Response Time Trends";
my $version     = '3.000.011';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);
my $now         = "$currentYear-$currentMonth-$currentDay ($currentHour:$currentMin:$currentSec)";
my $startTime   = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);
my $endDate;

# URL Access Parameters
my $cgi = new CGI;
my $pagedir     = (defined $cgi->param('pagedir'))   ? $cgi->param('pagedir')   : "index"; $pagedir =~ s/\+/ /g;
my $pageset     = (defined $cgi->param('pageset'))   ? $cgi->param('pageset')   : "index-cv"; $pageset =~ s/\+/ /g;
my $debug       = (defined $cgi->param('debug'))     ? $cgi->param('debug')     : "F";
my $selDetailed = (defined $cgi->param('detailed'))  ? $cgi->param('detailed')  : "on";
my $uKey1       = (defined $cgi->param('uKey1'))     ? $cgi->param('uKey1')     : "none";
my $uKey2       = (defined $cgi->param('uKey2'))     ? $cgi->param('uKey2')     : "none";
my $uKey3       = (defined $cgi->param('uKey3'))     ? $cgi->param('uKey3')     : "none";
my $startDate   = (defined $cgi->param('startDate')) ? $cgi->param('startDate') : "$currentYear-$currentMonth-$currentDay";
my $inputType   = (defined $cgi->param('inputType')) ? $cgi->param('inputType') : "fromto";
my $selYear     = (defined $cgi->param('year'))      ? $cgi->param('year')      : 0;
my $selWeek     = (defined $cgi->param('week'))      ? $cgi->param('week')      : 0;
my $selMonth    = (defined $cgi->param('month'))     ? $cgi->param('month')     : 0;
my $selQuarter  = (defined $cgi->param('quarter'))   ? $cgi->param('quarter')   : 0;
my $statuspie   = (defined $cgi->param('statuspie')) ? $cgi->param('statuspie') : "off";
my $errorpie    = (defined $cgi->param('errorpie'))  ? $cgi->param('errorpie')  : "off";
my $bar         = (defined $cgi->param('bar'))       ? $cgi->param('bar')       : "off";
my $hourlyAvg   = (defined $cgi->param('hourlyAvg')) ? $cgi->param('hourlyAvg') : "off";
my $dailyAvg    = (defined $cgi->param('dailyAvg'))  ? $cgi->param('dailyAvg')  : "off";
my $details     = (defined $cgi->param('details'))   ? $cgi->param('details')   : "off";
my $topx        = (defined $cgi->param('topx'))      ? $cgi->param('topx')      : "off";
my $pf          = (defined $cgi->param('pf'))        ? $cgi->param('pf')        : "off";
my $htmlToPdf   = (defined $cgi->param('htmlToPdf')) ? $cgi->param('htmlToPdf') : 0;

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

if ( $cgi->param('endDate') ) { $endDate = $cgi->param('endDate'); } else { $endDate = ""; }
my $htmlTitle   = ( $selDetailed eq "on" ) ? "Detailed Statistics and Report Generation" : "Compare Response Time Trends";

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Reports", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&detailed=$selDetailed&uKey1=$uKey1&uKey2=$uKey2&uKey3=$uKey3&startDate=$startDate&endDate=$endDate&inputType=$inputType&year=$selYear&week=$selWeek&month=$selMonth&quarter=$selQuarter&statuspie=$statuspie&errorpie=$errorpie&bar=$bar&hourlyAvg=$hourlyAvg&dailyAvg=$dailyAvg&details=$details&topx=$topx&pf=$pf";

# Debug information
print "<pre>pagedir   : $pagedir<br>pageset   : $pageset<br>debug     : $debug<br>CGISESSID : $sessionID<br>detailed  : $selDetailed<br>uKey1     : $uKey1<br>uKey2     : $uKey2<br>uKey3     : $uKey3<br>startDate : $startDate<br>endDate   : $endDate<br>inputType : $inputType<br>selYear   : $selYear<br>selWeek   : $selWeek<br>selMonth  : $selMonth<br>selQuarter: $selQuarter<br>statuspie : $statuspie<br>errorpie  : $errorpie<br>bar       : $bar<br>hourlyAvg : $hourlyAvg<br>dailyAvg  : $dailyAvg<br>details   : $details<br>topx      : $topx<br>pf        : $pf<br>htmlToPdf : $htmlToPdf<br>URL ...   : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  my ($rv, $dbh, $sth, $uKey, $sqlQuery, $sqlSelect, $sqlAverage, $sqlInfo, $sqlErrors, $sqlWhere, $sqlPeriode);
  my ($printerFriendlyOutputBox, $uKeySelect1, $uKeySelect2, $uKeySelect3, $images);
  my ($subtime, $endTime, $duration, $seconden, $status, $statusMessage, $title, $rest, $dummy, $count);
  my ($averageQ, $numbersOfTestsQ, $startDateQ, $stepQ, $endDateQ, $errorMessage, $chartOrTableChecked);
  my ($checkbox, $tables, $infoTable, $topxTable, $errorDetailList, $errorList, $responseTable, $goodDate);
  my ($fromto, $years, $weeks, $months, $quarters, $selectedYear, $selectedWeek, $selectedMonth, $selectedQuarter, $i);
  my @arrMonths = qw(January Februari March April May June July August September October November December);

  # open connection to database and query data
  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);

  if ( $dbh and $rv ) {
    $sqlQuery = "select uKey, LTRIM(SUBSTRING_INDEX(title, ']', -1)) as optionValueTitle from $SERVERTABLPLUGINS where environment = '$environment' and pagedir REGEXP '/$pageDir/' and production = '1' and activated = 1 order by optionValueTitle";
    $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);
    $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;
    $sth->bind_columns( \$uKey, \$title) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID) if $rv;

    if ( $rv ) {
      $dummy = ($uKey1 eq "none") ? " selected" : "";
      $uKeySelect1 = "          <option value=\"none\"$dummy>-Select-</option>\n";

      $dummy = ($uKey2 eq "none") ? " selected" : "";
      $uKeySelect2 .= "          <option value=\"none\"$dummy>-Select-</option>\n";

      $dummy = ($uKey3 eq "none") ? " selected" : "";
      $uKeySelect3 .= "          <option value=\"none\"$dummy>-Select-</option>\n";

      while( $sth->fetch() ) {
        $htmlTitle = "Results for $title" if ($uKey eq $uKey1 and $selDetailed eq "on");

        $dummy = ($uKey eq $uKey1) ? " selected" : "";
        $uKeySelect1 .= "          <option value=\"$uKey\"$dummy>$title</option>\n";

        $dummy = ($uKey eq $uKey2) ? " selected" : "";
        $uKeySelect2 .= "          <option value=\"$uKey\"$dummy>$title</option>\n";
	
        $dummy = ($uKey eq $uKey3) ? " selected" : "";
        $uKeySelect3 .= "          <option value=\"$uKey\"$dummy>$title</option>\n";
      }

      $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', $sessionID);

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
EndOfHtml
      } else {
        print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, '', 'F', "<script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/AnchorPosition.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/CalendarPopup.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/date.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/PopupWindow.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\">document.write(getCalendarStyles());</script>", $sessionID);
      }

      # Section: FromTo
      $dummy  = ($inputType eq "fromto") ? " checked" : "";
      $fromto = "<input type=\"radio\" name=\"inputType\" value=\"fromto\"$dummy>From:";

      # Section: Years
      $dummy  = ($inputType eq "year") ? " checked" : "";
      $years  = "<input type=\"radio\" name=\"inputType\" value=\"year\"$dummy>Year:</td><td>\n";
      $years .= "        <select name=\"year\">\n";
      ($selectedWeek, $selectedYear) = Week_of_Year( $currentYear, $currentMonth, $currentDay );
      $selectedYear = $selYear if ($selYear != 0);

      my ($firstSelectedYear, undef, undef) = split (/-/, $FIRSTSTARTDATE);

      for ($i = $firstSelectedYear; $i <= $currentYear; $i++) {
        $dummy = ($i == $selectedYear) ? " selected" : "";
        $years .= "          <option value=\"". $i ."\"$dummy>". $i ."</option>\n";
      }

      $years .= "        </select>";

      # Section: Weeks
      $dummy = ($inputType eq "week") ? " checked" : "";
      $weeks = "<input type=\"radio\" name=\"inputType\" value=\"week\"$dummy>Week:</td><td>";
      $weeks .= "        <select name=\"week\">\n";
      $selectedWeek = $selWeek if ($selWeek != 0);

      for ($i = 1; $i <= 53; $i++) {
        $dummy = ($i == $selectedWeek) ? " selected" : "";
        $weeks .= "          <option value=\"". $i ."\"$dummy>". $i ."</option>\n";
      }

      $weeks .= "        </select>\n";

      # Section: Months
      $dummy  = ($inputType eq "month") ? " checked" : "";
      $months = "<input type=\"radio\" name=\"inputType\" value=\"month\"$dummy>Month:</td><td>\n";
      $months .= "        <select name=\"month\">\n";
      $selectedMonth = ($selMonth == 0) ? $localMonth : $selMonth - 1;

      for ($i = 0; $i < 12; $i++) {
        $dummy = ($i == $selectedMonth) ? " selected" : "";
        $months .= "          <option value=\"". ($i+1) ."\"$dummy>". $arrMonths[$i] ."</option>\n";
      }

      $months .= "        </select>\n";

      # Section: Quarters
      $dummy     = ($inputType eq "quarter") ? " checked" : "";
      $quarters  = "<input type=\"radio\" name=\"inputType\" value=\"quarter\"$dummy>Quarter:</td><td>\n";
      $quarters .= "        <select name=\"quarter\">\n";
      $selectedQuarter = ($selQuarter == 0) ?  (int (($localMonth + 2) / 3)) : $selQuarter;

      for ($i = 1; $i <= 4; $i++) {
        $dummy = ($i == $selectedQuarter) ? " selected" : "";
        $quarters .= "          <option value=\"". $i ."\"$dummy>". $i ."</option>\n";
      }

      $quarters .= "        </select>\n";

      # Components for the selection of the charts  - - - - - - - - - - - -
      $checkbox = $tables = "";
      $chartOrTableChecked = 0;
      $errorMessage = "<br>Select application<br>\n" if ($uKey1 eq "none");

      if ( $selDetailed eq "on") {
        if ($statuspie eq "on") {
          $dummy = " checked";
          $chartOrTableChecked = 1;
          $images .= "<br><center><img src=/cgi-bin/generateChart.pl?chart=Status&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne "none");
        } else {
          $dummy = "";
        }

        $checkbox .= "        <input type=\"checkbox\" name=\"statuspie\"$dummy> Status\n";

        if ($errorpie eq "on") {
          $dummy = " checked";
          $chartOrTableChecked = 1;
          $images .= "<br><center><img src=/cgi-bin/generateChart.pl?chart=ErrorDetails&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne "none");
        } else {
          $dummy = "";
        }

        $checkbox .= "        <input type=\"checkbox\" name=\"errorpie\"$dummy> Error Details\n";

        if ($bar eq "on") {
          $dummy = " checked";
          $chartOrTableChecked = 1;
          $images .= "<br><center><img src=/cgi-bin/generateChart.pl?chart=Bar&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne "none");
        } else {
          $dummy = "";
        }

        $checkbox .= "        <input type=\"checkbox\" name=\"bar\"$dummy> Bar\n";
      }

      if ($hourlyAvg eq "on") {
        $dummy = " checked";
        $chartOrTableChecked = 1;
        $images .= "<br><center><img src=/cgi-bin/generateChart.pl?chart=HourlyAverage&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne "none");
      } else {
        $dummy = "";
      }
			
      $checkbox .= "        <input type=\"checkbox\" name=\"hourlyAvg\"$dummy> Hourly Average \n";

      if ($dailyAvg eq "on") {
        $dummy = " checked";
        $chartOrTableChecked = 1;
        $images .= "<br><center><img src=/cgi-bin/generateChart.pl?chart=DailyAverage&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne "none");
      } else {
        $dummy = "";
      }
			
      $checkbox .= "        <input type=\"checkbox\" name=\"dailyAvg\"$dummy> Daily Average (long term stats)";

      $dummy = ($pf eq "on") ? " checked" : "";
      $printerFriendlyOutputBox = "<input type=\"checkbox\" name=\"pf\"$dummy> Printer friendly output\n";

      my ($numberOfDays, $sqlStartDate, $sqlEndDate, $yearFrom, $monthFrom, $dayFrom, $yearTo, $monthTo, $dayTo);
      ($goodDate, $sqlStartDate, $sqlEndDate, $numberOfDays) = get_sql_startDate_sqlEndDate_numberOfDays_test ($STRICTDATE, $FIRSTSTARTDATE, $inputType, $selYear, $selQuarter, $selMonth, $selWeek, $startDate, $endDate, $currentYear, $currentMonth, $currentDay, $debug);
      $errorMessage .= "<br><font color=\"Red\">Wrong Startdate and/or Enddate</font><br>" unless ( $goodDate );

      if ( $selDetailed eq "on" ) {
        if ($details eq "on") {
          $dummy = " checked";
          $chartOrTableChecked = 1;
        } else {
          $dummy = "";
        }

        $tables .= "<input type=\"checkbox\" name=\"details\"$dummy> Show Details\n";

        if ($topx eq "on") {
          $dummy = " checked";
          $chartOrTableChecked = 1;
        } else {
          $dummy = "";
        }

        $tables .= "        <input type=\"checkbox\" name=\"topx\"$dummy> Show Top 20 Slow tests<br>";

        # Sql init & Query's  - - - - - - - - - - - - - - - - - - - - - -
        if ((($details eq "on") or ($topx eq "on")) and ! defined $errorMessage) {
          $sqlSelect  = "select startDate as startDateQ, startTime, endDate as endDateQ, endTime, duration, status, statusMessage";
          $sqlAverage = "select avg(duration) as average";
          $sqlErrors  = "select statusmessage, count(*) as aantal";
          $sqlWhere   = "WHERE uKey = '$uKey1'";
          $sqlPeriode = "AND startDate BETWEEN '$sqlStartDate' AND '$sqlEndDate' " if (defined $sqlStartDate and defined $sqlEndDate);
        }

        my ($numbersOfTests, $step, $average);
		
        if ($details eq "on" and ! defined $errorMessage) {
          # Details: General information  - - - - - - - - - - - - - - - - -
          $sqlInfo  = "select count(id) as numbersOfTests, max(step) as step";
          $sqlQuery = create_sql_query_events_from_range_year_month ($sqlStartDate, $sqlEndDate, $sqlInfo, "force index (key_startDate)", $sqlWhere, $sqlPeriode, '', "group by uKey", '', "", "ALL");

          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$numbersOfTestsQ, \$stepQ ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            while( $sth->fetch() ) {
              $numbersOfTests += $numbersOfTestsQ if (defined $numbersOfTestsQ);
			  $step = $stepQ if (defined $stepQ);
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }

          # Average: General information  - - - - - - - - - - - - - - - - -
          $sqlQuery = create_sql_query_events_from_range_year_month ($sqlStartDate, $sqlEndDate, $sqlAverage, "force index (key_startDate)", $sqlWhere, $sqlPeriode, "AND status = 'OK'", '', "", '', "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$averageQ ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            my $numberOffAverage = 0;

            while( $sth->fetch() ) { 
              if (defined $averageQ) {
                $numberOffAverage++;
                $average += $averageQ;
              }
            }

            $average /= $numberOffAverage if ($numberOffAverage != 0);
            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }

          # General information table - - - - - - - - - - - - - - - - - - -
          $infoTable = "<H1>General Information</H1>\n";
          $infoTable .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"200\">Entry</th><th>Value</th></tr>\n";
          $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Application</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .substr($htmlTitle, 11). " </td></tr>\n";
          $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Report Type</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .$inputType. " </td></tr>\n";
          $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Generated on</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">" .$now. "</td></tr>\n";
          $infoTable .= "  <tr><td colspan=\"2\"><br></td></tr>\n";
          $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Average (ok only)</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .substr($average,0,5). " seconds </td></tr>\n" if (defined $average);

          if (($step >= 1) and ($numberOfDays >= 1)) {
            $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Test interval</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .($step/60). " minutes</td></tr>\n";
            $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Should run 'X' tests:</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .((86400/$step)* $numberOfDays). " </td></tr>\n";
            $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Number of tests run </td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .$numbersOfTests. " (".substr(($numbersOfTests/((86400/$step)* $numberOfDays))*100,0,6)."%)</td></tr>\n";
          }

          $infoTable .= "</table>\n";

          # Problem Detail  - - - - - - - - - - - - - - - - - - - - - - - -
          my ($oneblock, $block, $firstrun, $nstartDateQ, $nstartTime, $nendDateQ, $nendTime, $nseconden);
          my ($tel, $wtel, $nstatus, $nrest, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $rrest);

          $errorList     = "<H1>Problem details</H1>\n";
          $responseTable = "<H1>Response time warnings</H1>\n";

          $sqlQuery = create_sql_query_events_from_range_year_month ($sqlStartDate, $sqlEndDate, $sqlSelect, "force index (key_startDate)", $sqlWhere, $sqlPeriode, "AND status <> 'OK' AND status <> 'OFFLINE' AND status <> 'NO TEST'", '', "", "order by startDateQ, startTime", "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$startDateQ, \$startTime, \$endDateQ, \$endTime, \$duration, \$status, \$statusMessage ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
  
          if ( $rv ) {
            $firstrun = 1; $oneblock = $tel = $wtel = 0;

            while( $sth->fetch() ) {
              $seconden = int(substr($duration, 6, 2)) + int(substr($duration, 3, 2)*60) + int(substr($duration, 0, 2)*3600);
              (undef, $rest) = split(/:/, $statusMessage, 2);
              ($rest, undef) = split(/\|/, $rest, 2) if (defined $rest); # remove performance data

              if ($firstrun) {
                $firstrun = 0;
              } else {
                ($oneblock, $block, $rrest, $dummy) = setBlockBGcolor ($oneblock, $status, $step, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest);

                if ($rrest =~ /^Response/) {
                  $wtel++;
                  $responseTable .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"40\"> # </th><th>Start</th><th>Stop</th><th>Duration</th><th>Status</th><th>Status Message</th></tr>\n" if ($wtel == 1);
                  $responseTable .= "<tr $block><td>$dummy$wtel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> ".encode_html_entities('S', $nstatus)." </font></td><td> ".encode_html_entities('M', $rrest)." </td></tr>\n";
                } else {
                  $tel++;
                  $errorList .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"40\"> # </th><th>Start</th><th>Stop</th><th>Duration</th><th>Status</th><th>Status Message</th></tr>\n" if ($tel == 1);
                  $errorList .= "<tr $block><td>$dummy$tel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS{$nstatus}."\"> ".encode_html_entities('S', $nstatus)." </font></td><td> ".encode_html_entities('M', $rrest)." </td></tr>\n";
                }
              }

              ($nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstartDateQ, $nstartTime, $nendDateQ, $nendTime, $nseconden, $nstatus, $nrest) = setPreviousValues ($startDateQ, $startTime, $endDateQ, $endTime, $seconden, $status, $rest);
            }

            if ($tel || $wtel) {
              ($oneblock, $block, $rrest, $dummy) = setBlockBGcolor ($oneblock, $status, 0, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest);
  
              if ($rrest =~ /^Response/) {
                $wtel++;
                $responseTable .= "<tr $block><td>$dummy$wtel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> ".encode_html_entities('S', $nstatus)." </font></td><td> ".encode_html_entities('M', $rrest)." </td></tr>\n";
              } else {
                $tel++;
                $errorList .= "<tr $block><td>$dummy$tel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> ".encode_html_entities('S', $nstatus)." </font></td><td> ".encode_html_entities('M', $rrest)." </td></tr>\n";
              }
            }

            $responseTable .= "</table>\n<br>\n<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td>Legende:</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">&nbsp;&nbsp;&nbsp;Single item&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">&nbsp;&nbsp;&nbsp;Start of block&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">&nbsp;&nbsp;&nbsp;Next element of the same block&nbsp;&nbsp;&nbsp;</td></tr></table>\n" if ($wtel);

            if ($tel) {
              $errorList .= "</table>\n<br>\n<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td>Legende:</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">&nbsp;&nbsp;&nbsp;Single item&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">&nbsp;&nbsp;&nbsp;Start of block&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">&nbsp;&nbsp;&nbsp;Next element of the same block&nbsp;&nbsp;&nbsp;</td></tr></table>\n";
            } else {
              $errorList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\"  bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">No problems for this period!</td></tr></table>\n";
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }

          $sqlQuery = create_sql_query_events_from_range_year_month ($sqlStartDate, $sqlEndDate, $sqlSelect, "force index (key_startDate)", $sqlWhere, $sqlPeriode, "AND status = 'OK' AND statusMessage regexp ': Response time [[:alnum:]]+.[[:alnum:]]+ > trendline [[:alnum:]]+'", '', "", "order by startDateQ, startTime", "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$startDateQ, \$startTime, \$endDateQ, \$endTime,\$duration, \$status, \$statusMessage ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            $oneblock = $wtel = 0; 

            while( $sth->fetch() ) {
              $seconden = int(substr($duration, 6, 2)) + int(substr($duration, 3, 2)*60) + int(substr($duration, 0, 2)*3600);
              (undef, $rest) = split(/:/, $statusMessage, 2);
              ($rest, undef) = split(/\|/, $rest, 2) if (defined $rest); # remove performance data

              if ($wtel) {
                ($oneblock, $block, $rrest, $dummy) = setBlockBGcolor ($oneblock, $status, $step, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest);
                $responseTable .= "<tr $block><td>$dummy$wtel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> " .encode_html_entities('S', $nstatus). " </font></td><td> " .encode_html_entities('M', $rrest). " </td></tr>\n";
              } else {
                $responseTable .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"40\"> # </th><th>Start</th><th>Stop</th><th>Duration</th><th>Status</th><th>Status Message</th></tr>\n";
              }

              $wtel++;
              ($nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstartDateQ, $nstartTime, $nendDateQ, $nendTime, $nseconden, $nstatus, $nrest) = setPreviousValues ($startDateQ, $startTime, $endDateQ, $endTime, $seconden, $status, $rest);
            }

            if ($wtel) {
              ($oneblock, $block, $rrest, $dummy) = setBlockBGcolor ($oneblock, $status, 0, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest);
              $responseTable .= "<tr $block><td>$dummy$wtel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> " .encode_html_entities('S', $nstatus). " </font></td><td> " .encode_html_entities('M', $rrest). " </td></tr>\n";

              $responseTable .= "</table>\n<br>\n<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td>Legende:</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">&nbsp;&nbsp;&nbsp;Single item&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">&nbsp;&nbsp;&nbsp;Start of block&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">&nbsp;&nbsp;&nbsp;Next element of the same block&nbsp;&nbsp;&nbsp;</td></tr></table>\n";
            } else {
              $responseTable .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">No response time warnings for this period!</td></tr></table>\n";
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }

          # Problem Summary - - - - - - - - - - - - - - - - - - - - - - -
          $sqlQuery = create_sql_query_events_from_range_year_month ($sqlStartDate, $sqlEndDate, $sqlErrors, "force index (key_startDate)", $sqlWhere, $sqlPeriode, "AND status ='CRITICAL'", "GROUP BY statusmessage", '', "order by aantal desc, statusmessage", "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$statusMessage, \$count ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            my (%problemSummary);

            if ($sth->rows) {
              while( $sth->fetch() ) {
                my ($dummy, $rest) = split(/:/, $statusMessage, 2);
                $rest = $dummy unless ( $rest );

                if ($rest) {
                  ($rest, undef) = split(/\|/, $rest, 2); # remove performance data
                  ($dummy, $rest) = split(/,/, $rest, 2);
                  $rest = $dummy unless ( $rest );
                } else {
                  $rest = 'UNDEFINED';
                }

                if (exists $problemSummary{$rest}) {
                  $problemSummary{$rest} += $count;
                } else {
                  $problemSummary{$rest}  = $count;
                }
              }
            }

            $errorDetailList = "<H1>Problem Summary </H1>\n";

  	        if ( $sth->rows > 0 ) {
  	          $errorDetailList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th>Statusmessage</th><th>Freq</th></tr>\n";

    	      foreach my $rest (sort {$problemSummary{$b} <=> $problemSummary{$a}} (keys(%problemSummary))) {
	            $errorDetailList .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td> " .encode_html_entities('M', $rest). " </td><td align=\"right\">" .$problemSummary{$rest}. "</td></tr>\n";
	          }

              $errorDetailList .= "</table>\n";
            } else {
              $errorDetailList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">No errors for this period!</td></tr></table>";
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }
        }

        if ($topx eq 'on' and ! defined $errorMessage) {
          # Top X List  - - - - - - - - - - - - - - - - - - - - - - - - -
          my ($startDatetx, $durationtx, $startTimetx);
          $sqlQuery = create_sql_query_events_from_range_year_month ($sqlStartDate, $sqlEndDate, "select startDate, startTime, duration", "force index (key_startDate)", $sqlWhere, $sqlPeriode, "and status <> 'OFFLINE' and status <> 'CRITICAL' and duration > 0", '', "", "order by duration desc, startDate desc, startTime desc limit 20", "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$startDatetx, \$startTimetx,\$durationtx ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            $topxTable .= "<H1>Top 20 Slow Tests </H1>\n";
            $topxTable .= "\n<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"40\"> # </th><th>Time</th><th>Duration</th></tr>\n";

            my $teltopx = 1;
	
            while( $sth->fetch() ) {
              $seconden = int(substr($durationtx, 6, 2)) + int(substr($durationtx, 3, 2)*60) + int(substr($durationtx, 0, 2)*3600);
              $topxTable .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td width=\"30\">$teltopx</td><td width=\"200\" align=\"center\">$startDatetx \@ $startTimetx</td><td width=\"80\" align=\"right\"><b>$seconden sec</b></td></tr>\n";
              $teltopx++;
            }			

            $topxTable .= "<tr><td width=\"400\">No top 20 slow tests for this period!</td></tr>\n" if ($teltopx == 1);
            $topxTable .= "</table>";
            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }
        }
      }

      $errorMessage .= "<br>There are no charts or tables checked<br>\n" unless ( $chartOrTableChecked );
    }

    # Close database connection - - - - - - - - - - - - - - - - - - - - -
    $dbh->disconnect or $rv = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', -1, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if ($htmlToPdf) {
      my ($type, $range);
		
      if ($inputType eq "fromto") {
        if ($endDate ne "")	{
          $type  = '';
          $range = "Between $startDate and $endDate";
        } else {
          $type  = ' Daily';
          $range = "Date $startDate";
        }
      } elsif ($inputType eq "year") {
        $type  = ' Yearly';
        $range = "Year $selYear";
      } elsif ($inputType eq "quarter") {
        $type  = ' Quarterly';
        $range = "Year $selYear, Quarter $selQuarter";
      } elsif ($inputType eq "month") {
        $type  = ' Monthly';
        $range = "Year $selYear, Month " .$arrMonths[$selMonth -1];
      } elsif ($inputType eq "week") {
        $type  = ' Weekly';
        $range = "Year $selYear, Week $selWeek";
      }

      print "    <H1>$DEPARTMENT \@ $BUSINESS: '$APPLICATION'$type report</H1>\n";
      print "    <H2>Periode: $range</H2>\n" if (defined $range);
    } else {
      print <<HTML;
  <form action="$ENV{SCRIPT_NAME}" method="post" name="reports">
    <input type="hidden" name="pagedir"   value="$pagedir">
    <input type="hidden" name="pageset"   value="$pageset">
    <input type="hidden" name="debug"     value="$debug">
    <input type="hidden" name="CGISESSID" value="$sessionID">
    <input type="hidden" name="detailed"  value="$selDetailed">
    <table border="0">
HTML

      if ( $selDetailed eq "on" ) {
        print <<HTML;
      <tr align="left"><td>Application:</td><td>
        <select name="uKey1">
$uKeySelect1        </select>
HTML
      } else {
        print <<HTML;
      <tr align="left"><td>Application 1:</td><td>
        <select name="uKey1">
$uKeySelect1        </select>
      </td></tr><tr align="left"><td>Application 2:</td><td>
        <select name="uKey2">
$uKeySelect2        </select>
      </td></tr><tr align="left"><td>Application 3:</td><td>
        <select name="uKey3">
$uKeySelect3        </select>
HTML
      }

      my ($firstStartdateYear, $firstStartdateMonth, $firstStartdateDay) = split (/-/, $FIRSTSTARTDATE);
      my ($firstYear, $firstMonth, $firstDay) = Add_Delta_Days ($firstStartdateYear, $firstStartdateMonth, $firstStartdateDay, -1);

      my ($lastYear, $lastMonth, $lastDay) = Add_Delta_Days ($currentYear, $currentMonth, $currentDay, 1);

      print <<HTML;
      </td></tr><tr align="left"><td>$fromto</td>
      <td><SCRIPT LANGUAGE="JavaScript" ID="jsCal1Calendar">
            var cal1Calendar = new CalendarPopup("CalendarDIV");
            cal1Calendar.offsetX = 1;
            cal1Calendar.showNavigationDropdowns();
            cal1Calendar.addDisabledDates(null, "$firstYear-$firstMonth-$firstDay");
            cal1Calendar.addDisabledDates("$lastYear-$lastMonth-$lastDay", null);
          </SCRIPT>
          <DIV ID="CalendarDIV" STYLE="position:absolute;visibility:hidden;background-color:black;layer-background-color:black;"></DIV>
	      <input type="text" name="startDate" value="$startDate" size="10" maxlength="10">&nbsp;
		  <a href="#" onclick="cal1Calendar.select(document.forms[0].startDate, 'startDateCalendar','yyyy-MM-dd'); return false;" name="startDateCalendar" id="startDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"> </a>&nbsp;&nbsp;
		  To: <input type="text" name="endDate" value="$endDate" size="10" maxlength="10">&nbsp;
		  <a href="#" onclick="cal1Calendar.select(document.forms[0].endDate, 'endDateCalendar','yyyy-MM-dd'); return false;" name="endDateCalendar" id="endDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"> </a>
      </td></tr><tr align="left"><td valign="top">$years
      </td></tr><tr align="left"><td valign="top">$quarters
      </td></tr><tr align="left"><td valign="top">$months
      </td></tr><tr align="left"><td valign="top">$weeks
      </td></tr><tr align="left"><td valign="top">Charts:</td><td>$checkbox
HTML

      print "      </td></tr><tr align=\"left\"><td valign=\"top\">Tables:</td><td>$tables\n" if ( $selDetailed eq "on" );

      print <<HTML;
      </td></tr><tr align="left"><td>Options:</td><td>$printerFriendlyOutputBox
      </td></tr><tr align="left"><td align="right"><br>
        <input type="submit" value="Launch"></td><td><br><input type="reset" value="Reset">
      </td></tr>
    </table>
  </form>
  <hr>
HTML
    }

    if (defined $errorMessage) {
      print $errorMessage, "\n" ;
    } else {
      print $images, "\n" if (defined $images );
      print $infoTable, "<br><br>\n" if (defined $infoTable);
      print $topxTable, "<br><br>\n" if (defined $topxTable);
      print $errorDetailList, "<br><br>\n" if (defined $errorDetailList);
      print $errorList, "<br><br>\n" if (defined $errorList);
      print $responseTable if (defined $responseTable);
      print "<br><center><a href=\"/cgi-bin/htmlToPdf.pl?HTMLtoPDFprg=$HTMLTOPDFPRG&amp;HTMLtoPDFhow=$HTMLTOPDFHOW&amp;scriptname=", $ENV{SCRIPT_NAME}, "&amp;",encode_html_entities('U', $urlAccessParameters),"\" target=\"_blank\">[Generate PDF file]</a></center>\n" if ((! defined $errorMessage) and ($HTMLTOPDFPRG ne '<nihil>' and $HTMLTOPDFHOW ne '<nihil>') and (! $htmlToPdf));
    }
  }

  print '<BR>', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub setBlockBGcolor {
  my ($oneblock, $status, $step, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest) = @_;

  my $block;

  if ($step == 0) {
    $block = ($oneblock) ? " bgcolor=\"$COLORSTABLE{ENDBLOCK}\" " : " bgcolor=\"$COLORSTABLE{NOBLOCK}\" ";
    $oneblock = 0;
  } else {
    my ($year, $month, $day) = split(/-/, $startDateQ);
    my ($hours, $minuts, $seconds) = split(/:/, $startTime);

    my ($ddays, $dhours, $dminuts, $dseconds) = Delta_DHMS ($nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $year, $month, $day, $hours, $minuts, $seconds);
    my $dtotsec = $dseconds + ($dminuts * 60) + ($dhours * 3600) + ($ddays * 86400);

    if (($dtotsec < ($step * 2.2)) and ($nstatus eq $status)) {
      $block = ($oneblock) ? " bgcolor=\"$COLORSTABLE{ENDBLOCK}\" " : " bgcolor=\"$COLORSTABLE{STARTBLOCK}\" ";
      $oneblock = 1;
    } else {
      $block = ($oneblock) ? " bgcolor=\"$COLORSTABLE{ENDBLOCK}\" " : " bgcolor=\"$COLORSTABLE{NOBLOCK}\" ";
      $oneblock = 0;
    }
  }

  my ($dummy, $rrest);

  if (defined $nrest) {
    ($dummy, $rrest) = split(/,/, $nrest, 2);
    $dummy = '' unless ( defined $dummy );
    $rrest = $dummy unless ( defined $rrest );
  } else {
    $rrest = '';
  }

  $rrest =~ s/^ +//g; 
  return ($oneblock, $block, $rrest, '');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub setPreviousValues {
  my ($startDateQ, $startTime, $endDateQ, $endTime, $seconden, $status, $rest) = @_;

  my ($nyear, $nmonth, $nday) = split(/-/, $startDateQ);
  my ($nhours, $nminuts, $nseconds) = split(/:/, $startTime);
  return ($nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $startDateQ, $startTime, $endDateQ, $endTime, $seconden, $status, $rest);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

