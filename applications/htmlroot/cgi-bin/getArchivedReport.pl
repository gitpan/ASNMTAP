#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# � Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/03/18, v3.000.006, getArchivedReport.pl for ASNMTAP::Asnmtap::Applications::CGI making Asnmtap v3.000.xxx compatible
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Date::Calc qw(Monday_of_Week Week_of_Year);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.000.006;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MEMBER :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "getArchivedReport.pl";
my $prgtext     = "Get Archived Report";
my $version     = '3.000.006';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $uKey        = (defined $cgi->param('uKey'))      ? $cgi->param('uKey')      : '<NIHIL>';  $uKey    =~ s/\+/ /g;
my $pagedir     = (defined $cgi->param('pagedir'))   ? $cgi->param('pagedir')   : "index";    $pagedir =~ s/\+/ /g;
my $pageset     = (defined $cgi->param('pageset'))   ? $cgi->param('pageset')   : "index-cv"; $pageset =~ s/\+/ /g;
my $debug       = (defined $cgi->param('debug'))     ? $cgi->param('debug')     : "F";
my $ascending   = (defined $cgi->param('ascending')) ? $cgi->param('ascending') : 0;
my $day         = (defined $cgi->param('day'))       ? $cgi->param('day')       : "off";
my $week        = (defined $cgi->param('week'))      ? $cgi->param('week')      : "off";
my $month       = (defined $cgi->param('month'))     ? $cgi->param('month')     : "off";
my $quarter     = (defined $cgi->param('quarter'))   ? $cgi->param('quarter')   : "off";
my $year        = (defined $cgi->param('year'))      ? $cgi->param('year')      : "off";

my $htmlTitle   = "Get Archived Report(s)";

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTiltle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Report Archive", "uKey=$uKey");

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&uKey=$uKey&ascending=$ascending&day=$day&week=$week&month=$month&quarter=$quarter&year=$year";

# Debug information
print "<pre>pagedir   : $pagedir<br>pageset   : $pageset<br>debug     : $debug<br>CGISESSID : $sessionID<br>uKey      : $uKey<br>ascending : $ascending<br>day       : $day<br>week      : $week<br>month     : $month<br>quarter   : $quarter<br>year      : $year<br>URL ...   : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  unless ( defined $userType ) {
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", 'F', '', $sessionID);
    print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n";
  } else {
    my ($rv, $dbh, $sth, $sql, $title, $resultsdir, $uKeySelect, $reportsSelect);

    # open connection to database and query data
    $rv  = 1;
    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY", ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);

    if ( $dbh and $rv ) {
      $sql = "select distinct $SERVERTABLPLUGINS.uKey, LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)) as optionValueTitle from $SERVERTABLREPORTS, $SERVERTABLPLUGINS where $SERVERTABLREPORTS.activated = 1 and $SERVERTABLPLUGINS.uKey = $SERVERTABLREPORTS.uKey and $SERVERTABLPLUGINS.pagedir REGEXP '/$pagedir/' order by optionValueTitle";
      ($rv, $uKeySelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $uKey, 'uKey', '', '', '', '', $pagedir, $pageset, $htmlTitle, $subTiltle, $sessionID, $debug);

      if ($uKey ne '<NIHIL>') {
        $sql = "select LTRIM(SUBSTRING_INDEX(title, ']', -1)), resultsdir from $SERVERTABLPLUGINS where uKey = '$uKey'";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID) if $rv;

        if ( $rv ) {
          ($title, $resultsdir) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID) if ($sth->rows);
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, "", $sessionID);
        } 
      }

      # Close database connection - - - - - - - - - - - - - - - - - - - - -
      $dbh->disconnect or $rv = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, "", "", "", "", "", -1, "", $sessionID);
    }

    if ($rv) {
      if (defined $resultsdir) {
        my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;uKey=$uKey&amp;day=$day&amp;week=$week&amp;month=$month&amp;quarter=$quarter&amp;year=$year";
        $reportsSelect = "  <table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='$COLORSTABLE{TABLE}'>\n    <tr><th colspan=\"2\"><a href=\"$urlWithAccessParameters&amp;ascending=0\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Report <a href=\"$urlWithAccessParameters&amp;ascending=1\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th></tr>";

        my $rvOpendir = opendir(REPORTS, "$RESULTSPATH/$resultsdir/$REPORTDIR/");

        if ($rvOpendir) {
          my @archivedReportFiles = readdir(REPORTS);
          closedir(REPORTS);

          if ($ascending) {
            @archivedReportFiles = sort { lc($a) cmp lc($b) } @archivedReportFiles; # alphabetical sort ascending
          } else {
            @archivedReportFiles = sort { lc($b) cmp lc($a) } @archivedReportFiles; # alphabetical sort descending
          }

          my $noGeneratedReports = 1;

          foreach my $archivedReportFile (@archivedReportFiles) {
            if ($archivedReportFile =~ /.pdf$/ and $archivedReportFile =~ /-$uKey-/) {
              my $reportYear  = substr($archivedReportFile, 0, 4);
		  	  my $reportMonth = substr($archivedReportFile, 4, 2);
			  my $reportDay   = substr($archivedReportFile, 6, 2);

              my ($reportPeriode, $reportDate);

              if ( $day eq 'on' and $archivedReportFile =~ /-Day_(\w+)-id_/ ) {
                $reportPeriode = "$1";
		  	    $reportDate    = "$reportYear/$reportMonth/$reportDay";
			  } elsif ( $week eq 'on' and $archivedReportFile =~ /-Week_(\d+)-id_/ ) {
                $reportPeriode = "Week: $1";
                ($reportYear, undef, undef) = Monday_of_Week(Week_of_Year($reportYear, $reportMonth, $reportDay));
			    $reportDate    = $reportYear;
              } elsif ( $month eq 'on' and $archivedReportFile =~ /-Month_(\w+)-id_/ ) {
                $reportPeriode = "Month: $1";
                $reportDate    = $reportYear;
		  	  } elsif ( $quarter eq 'on' and $archivedReportFile =~ /-Quarter_(\d+)-id_/ ) {
                $reportPeriode = "Quarter: $1";
                $reportDate    = $reportYear;
              } elsif ( $year eq 'on' and $archivedReportFile =~ /-Year_(\d+)-id_/ ) {
                $reportPeriode = "Year: $1";
                $reportDate    = "&nbsp;";
              }

              if (defined $reportPeriode) {
                $reportsSelect .= "\n    <tr><td><a href=\"$RESULTSURL/$resultsdir/$REPORTDIR/$archivedReportFile\" target=\"_blank\">$reportPeriode</a></td><td>$reportDate</td></tr>";
                $noGeneratedReports = 0;
              }
            }
          }

          $reportsSelect .= "\n    <tr><td>For this periode there are no generated report(s) for '" .encode_html_entities('T', $title). "'</td></tr>" if ($noGeneratedReports);
        }

        $reportsSelect .= "\n  </table>";
      } else {
        $reportsSelect = "<h1>Contact the administrator, maybe no reports defined</h1><br>" if ($uKey ne '<NIHIL>');
      }

      # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      my $onload = ($uKey ne '<NIHIL>') ? "ONLOAD=\"if (document.images) document.Progress.src='".$IMAGESURL."/spacer.gif';\"" : "";
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTiltle, 3600, $onload, 'F', '', $sessionID);

      my $urlWithAccessParameters = "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

      if ( $userType >= 1 ) {
        print <<EndOfHtml;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
        <td class="StatusItem"><a href="getArchivedReport.pl$urlWithAccessParameters">[List report archive]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="getArchivedDebug.pl$urlWithAccessParameters">[List debug archive]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="getArchivedResults.pl$urlWithAccessParameters">[List results archive]</a></td>
	  </tr></table>
	</td></tr>
  </table>
EndOfHtml
      }

      my $checkboxDay     = "<input type=\"checkbox\" name=\"day\"" .(($day eq "on") ? ' checked' : ''). "> Daily";
      my $checkboxWeek    = "<input type=\"checkbox\" name=\"week\"" .(($week eq "on") ? ' checked' : ''). "> Weekly";
      my $checkboxMonth   = "<input type=\"checkbox\" name=\"month\"" .(($month eq "on") ? ' checked' : ''). "> Monthly";
      my $checkboxQuarter = "<input type=\"checkbox\" name=\"quarter\"" .(($quarter eq "on") ? ' checked' : ''). "> Quarterly";
      my $checkboxYear    = "<input type=\"checkbox\" name=\"year\"" .(($year eq "on") ? ' checked' : ''). "> Yearly";
	  
      print <<EndOfHtml;
	  </tr></table>
	</td></tr>
  </table>
  <BR>
  <form action="$ENV{SCRIPT_NAME}" name="params">
    <input type="hidden" name="pagedir"   value="$pagedir">
    <input type="hidden" name="pageset"   value="$pageset">
    <input type="hidden" name="debug"     value="$debug">
    <input type="hidden" name="CGISESSID" value="$sessionID">
    <input type="hidden" name="ascending" value="$ascending">
    <table border=0>
	  <tr align="left"><td>Application:</td><td>$uKeySelect</td></tr>
	  <tr align="left"><td>Periode:</td><td>$checkboxDay $checkboxWeek $checkboxMonth $checkboxQuarter $checkboxYear</td></tr>
      <tr align="left"><td align="right"><br><input type="submit" value="Go"></td><td><br><input type="reset" value="Reset"></td></tr>
    </table>
  </form>
  <HR>
EndOfHtml

      if (defined $reportsSelect) {
        print "<br>$reportsSelect";
      } else {
        print "<br>Select application from the 'Archived Report Directory'.<br>";
      }
    }

    print '<BR>', "\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -