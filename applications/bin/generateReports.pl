#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# � Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/05/01, v3.000.008, generateReports.pl for ASNMTAP::Applications making Asnmtap v3.000.xxx compatible
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Date::Calc qw(Add_Delta_Days Day_of_Week Days_in_Month Week_of_Year);
use Time::Local;
use Getopt::Long;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications v3.000.008;
use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS &call_system

                                      $REPORTDIR
                                      $RESULTSPATH
                                      $REMOTE_HOST $HTTPSURL
                                      $HTMLTOPDFPRG $HTMLTOPDFOPTNS
                                      &create_header &create_footer
                                      &init_email_report &send_email_report &encode_html_entities
                                      &error_Trap_DBI

                                      $DATABASE $SERVERNAMEREADONLY $SERVERPORTREADONLY $SERVERUSERREADONLY $SERVERPASSREADONLY
                                      $SERVERTABLPLUGINS $SERVERTABLREPORTS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_y $opt_m $opt_d $opt_a $opt_u  $opt_V $opt_h $opt_D $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "generateReports.pl";
my $prgtext     = "Generate Reports for the '$APPLICATION'";
my $version     = '3.000.008';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $debug       = 0;                                            # default
my $daysAfter   = 3;                                            # default

my $currentYear = ((localtime)[5])+1900;                        # default
my $currentMonth= ((localtime)[4])+1;                           # default
my $currentDay  = ((localtime)[3]);                             # default

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');

GetOptions (
  "y:s" => \$opt_y, "year:s"        => \$opt_y,
  "m:s" => \$opt_m, "month:s"       => \$opt_m,
  "d:s" => \$opt_d, "day:s"         => \$opt_d,
  "a:s" => \$opt_a, "daysafter:s"   => \$opt_a,
  "u:s" => \$opt_u, "ukey:s"        => \$opt_u,
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "D:s" => \$opt_D, "debug:s"       => \$opt_D,
  "V"   => \$opt_V, "version"       => \$opt_V,
  "h"   => \$opt_h, "help"          => \$opt_h
);

if ($opt_V) { print_revision($PROGNAME, $version); exit $ERRORS{OK}; }
if ($opt_h) { print_help(); exit $ERRORS{OK}; }

if ($opt_D) {
  if ($opt_D eq 'F' || $opt_D eq 'T' || $opt_D eq 'L') {
    $debug = 0 if ($opt_D eq 'F');
    $debug = 1 if ($opt_D eq 'T');
    $debug = 2 if ($opt_D eq 'L');
  } else {
    usage("Invalid debug: $opt_D\n");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ($opt_a) {
  if ($opt_a =~ /^[0-9]+$/) {
    $daysAfter = $opt_a;
  } else {
    usage("Invalid days after: $opt_a\n");
  }
}

my $uKeySqlWhere = (defined $opt_u) ? 'uKey = "' .$opt_u .'" AND' : '';

if ($opt_y) {
  if ($opt_y =~ /^20\d\d$/) {
    $currentYear = $opt_y;
  } else {
    usage("Invalid current year: $opt_y\n");
  }
}

if ($opt_m) {
  if ($opt_m =~ /^([1-9]|1[012])$/) {
    $currentMonth = $opt_m;
  } else {
    usage("Invalid current month: $opt_m\n");
  }
}

if ($opt_d) {
  if ($opt_d =~ /^([1-9]|[12][0-9]|3[01])$/) {
    my $daysInMonth = Days_in_Month($currentYear, $currentMonth); 

    if ( $opt_d <= $daysInMonth) {
      $currentDay = $opt_d;
    } else {
      usage("Invalid current day: $opt_d\n");
    }
  } else {
    usage("Invalid current day: $opt_d\n");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($emailReport, $rvOpen) = init_email_report (*EMAILREPORT, "generateReports.txt", $debug);

create_dir ($RESULTSPATH);

my @arrayDays   = ('<NIHIL>', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');
my @arrayMonths = ('<NIHIL>', 'January', 'Februari', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

for (my $dayAfter = 1; $dayAfter <= $daysAfter; $dayAfter++) {
  my ($urlAccessParametersDay, $urlAccessParametersWeek, $urlAccessParametersMonth, $urlAccessParametersQuarter, $urlAccessParametersYear);
  my $emailMessage = "\n";

  # Yesterday - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  my ($dayReportYear, $dayReportMonth, $dayReportDay) = Add_Delta_Days ( $currentYear, $currentMonth, $currentDay, -$dayAfter );
  $emailMessage .= "Report Daily     : for day $dayReportDay from the month $dayReportMonth into the year $dayReportYear\n";
  $urlAccessParametersDay = "inputType=fromto&startDate=$dayReportYear-$dayReportMonth-$dayReportDay&endDate=";
  my $dayReportDayOfWeek = Day_of_Week ($dayReportYear, $dayReportMonth, $dayReportDay);

  # Last day of the week  - - - - - - - - - - - - - - - - - - - - - - - -
  my $weekReportWeek = 0;

  if ($dayReportDayOfWeek == 7) {
    my $weekReportYear;
    ($weekReportWeek, $weekReportYear) = Week_of_Year( $dayReportYear, $dayReportMonth, $dayReportDay ); 
    $emailMessage .= "Report Weekly    : for week $weekReportWeek into the year $weekReportYear\n";
    $urlAccessParametersWeek = "inputType=week&year=$weekReportYear&week=$weekReportWeek";
  }

  # Last day of the month - - - - - - - - - - - - - - - - - - - - - - - -
  my $dayReportDaysInMonth = Days_in_Month($dayReportYear, $dayReportMonth);

  if ($dayReportDay == $dayReportDaysInMonth) {
    $emailMessage .= "Report Monthly   : for month $dayReportMonth into the year $dayReportYear\n";
    $urlAccessParametersMonth = "inputType=month&year=$dayReportYear&month=$dayReportMonth";
  }

  # Last day of a quarter - - - - - - - - - - - - - - - - - - - - - - - -
  my $quarterReportQuarter = 0;

  if (($dayReportMonth == 3 or $dayReportMonth == 6 or $dayReportMonth == 9 or $dayReportMonth == 12) and $dayReportDay == $dayReportDaysInMonth) {
    $quarterReportQuarter = int(($dayReportMonth + 2) / 3);
    $emailMessage .= "Report Quarterly : for quarter $quarterReportQuarter into the year $dayReportYear\n";
    $urlAccessParametersQuarter = "inputType=quarter&year=$dayReportYear&quarter=$quarterReportQuarter";
  }

  # Last day of the year - - - - - - - - - - - - - - - - - - - - - - - - -
  my $yearReportYear = 0;

  if ($dayReportMonth == 12 and $dayReportDay == 31) {
    $yearReportYear = $currentYear - 1;
    $emailMessage .= "Report Yearly    : for the year $yearReportYear\n";
    $urlAccessParametersYear = "inputType=year&year=$yearReportYear";
  }

  if ( $debug ) { print $emailMessage; } else { print EMAILREPORT $emailMessage; }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Init parameters
  my ($rv, $dbh, $sth, $sql);

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot connect to the database", $debug);

  if ($dbh and $rv) {
    my ($id, $uKey, $reportTitle, $periode, $status, $errorDetails, $bar, $hourlyAverage, $dailyAverage, $showDetails, $showTop20SlowTests, $printerFriendlyOutput, $formatOutput, $test, $resultsdir);
    $sql = "select id, uKey, reportTitle, periode, status, errorDetails, bar, hourlyAverage, dailyAverage, showDetails, showTop20SlowTests, printerFriendlyOutput, formatOutput from $SERVERTABLREPORTS where $uKeySqlWhere activated = '1' order by uKey";
    $sth = $dbh->prepare( $sql ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot dbh->prepare: $sql", $debug);
    $sth->execute() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug) if $rv;
    $sth->bind_columns( \$id, \$uKey, \$reportTitle, \$periode, \$status, \$errorDetails, \$bar, \$hourlyAverage, \$dailyAverage, \$showDetails, \$showTop20SlowTests, \$printerFriendlyOutput, \$formatOutput ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->bind_columns: $sql", $debug) if $rv;

    my @commands = (); my @pdfFilenames = ();

    if ( $rv ) {
      if ( $sth->rows ) {
        while( $sth->fetch() ) {
          $emailMessage = ($debug >= 2) ? "--> $id, $uKey, $reportTitle, $periode, $status, $errorDetails, $bar, $hourlyAverage, $dailyAverage, $showDetails, $showTop20SlowTests, $printerFriendlyOutput, $formatOutput\n" : "";
          my ($urlAccessParameters, $periodeMessage);
          
          if ($periode eq 'D') {
            $periodeMessage = "Day_$arrayDays[$dayReportDayOfWeek]";
            $emailMessage .= " -> Daily\n" if ($debug >= 2);
            $urlAccessParameters = $urlAccessParametersDay if (defined $urlAccessParametersDay);
          } elsif ($periode eq 'W') {
            $periodeMessage = "Week_$weekReportWeek";
            $emailMessage .= " -> Weekly\n" if ($debug >= 2);
            $urlAccessParameters = $urlAccessParametersWeek if (defined $urlAccessParametersWeek);
          } elsif ($periode eq 'M') {
            $periodeMessage = "Month_$arrayMonths[$dayReportMonth]";
            $emailMessage .= " -> Monthly\n" if ($debug >= 2);
            $urlAccessParameters = $urlAccessParametersMonth if (defined $urlAccessParametersMonth);
          } elsif ($periode eq 'Q') {
            $periodeMessage = "Quarter_$quarterReportQuarter";
            $emailMessage .= " -> Quarterly\n" if ($debug >= 2);
            $urlAccessParameters = $urlAccessParametersQuarter if (defined $urlAccessParametersQuarter);
          } elsif ($periode eq 'Y') {
            $periodeMessage = "Year_$yearReportYear";
            $emailMessage .= " -> Yearly\n" if ($debug >= 2);
            $urlAccessParameters = $urlAccessParametersYear if (defined $urlAccessParametersYear);
          } else {
            $periodeMessage = 'Never';
            $emailMessage .= " -> None\n" if ($debug >= 2);
          }

          if (defined $urlAccessParameters) {
            $urlAccessParameters  = "htmlToPdf=1&$urlAccessParameters";
            $urlAccessParameters .= "&uKey1=$uKey&uKey2=none&uKey3=none";
            $urlAccessParameters .= "&detailed=on";
            $urlAccessParameters .= "&statuspie=on" if($status);
            $urlAccessParameters .= "&errorpie=on" if($errorDetails);
            $urlAccessParameters .= "&bar=on" if($bar);
            $urlAccessParameters .= "&hourlyAvg=on" if($hourlyAverage);
            $urlAccessParameters .= "&dailyAvg=on" if($dailyAverage);
            $urlAccessParameters .= "&details=on" if($showDetails);
            $urlAccessParameters .= "&topx=on" if($showTop20SlowTests);
            $urlAccessParameters .= "&pf=on" if($printerFriendlyOutput);

            $sql = "select test, resultsdir from $SERVERTABLPLUGINS where ukey = '$uKey' order by uKey";
            my $sth = $dbh->prepare( $sql ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot dbh->prepare: $sql", $debug);
            $sth->execute() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug) if $rv;

            if ( $rv ) {
              ($test, $resultsdir) = $sth->fetchrow_array() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug) if $rv;
               $sth->finish() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug);
            }

            my $logging = $RESULTSPATH .'/'. $resultsdir;
            create_dir ($logging);

            my $reports = $logging .'/'. $REPORTDIR;
            create_dir ($reports);

            $logging .= "/";
            create_header ($logging."HEADER.html");
            create_footer ($logging."FOOTER.html");

            $reports .= "/";
            create_header ($reports."HEADER.html");
            create_footer ($reports."FOOTER.html");

            my $dayReportMonthPdf = ($dayReportMonth < 10) ? "0$dayReportMonth" : $dayReportMonth;
		    my $dayReportDayPdf = ($dayReportDay < 10) ? "0$dayReportDay" : $dayReportDay;
            my $pdfFilename = "$RESULTSPATH/$resultsdir/$REPORTDIR/$dayReportYear$dayReportMonthPdf$dayReportDayPdf-$test-$uKey-$periodeMessage-id_$id.pdf";
            my $encodedUrlAccessParameters = encode_html_entities('U', $urlAccessParameters);
            my $command = "$HTMLTOPDFPRG -f '$pdfFilename' $HTMLTOPDFOPTNS 'http://$REMOTE_HOST/cgi-bin/detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl?$encodedUrlAccessParameters'";

            if ( -e "$pdfFilename" ) {
              $emailMessage .= "  > $pdfFilename exists\n";
            } else {
              $emailMessage .= "  > $pdfFilename will be generated\n";
              push (@commands, $command);
              push (@pdfFilenames, $pdfFilename);
            }
          }

          if ( $debug ) { print $emailMessage; } else { print EMAILREPORT $emailMessage; }
        }
      }

      $sth->finish() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->finish: $sql", $debug);
    }

    $dbh->disconnect or $rv = error_Trap_DBI(*EMAILREPORT, "Sorry, the database was unable to add your entry.", $debug);
    my $teller = 0;
    $emailMessage .= "\n";

    foreach my $command (@commands) {
      if ($HTMLTOPDFPRG eq 'HTMLDOC') {
        $ENV{HTMLDOC_NOCGI} = 1;
        select(STDOUT);  $| = 1;
      }

      my ($status, $stdout, $stderr) = call_system ("$command", $debug);

      unless ( $status == 0 and $stdout eq '' and $stderr eq '' ) {
        $emailMessage .= "call_system: command: $command, status: $status, stdout: $stdout, stderr: $stderr\n";
      } else {
        $emailMessage .= $pdfFilenames[$teller]. " generated\n";
      }

      $teller++;
    }

    if ( $debug ) { print $emailMessage; } else { print EMAILREPORT $emailMessage; }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($rc) = send_email_report (*EMAILREPORT, $emailReport, $rvOpen, $prgtext, $debug);

exit;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_dir {
  my ($directory) = @_;

  unless ( -e "$directory" ) {                        # create $directory
    my ($status, $stdout, $stderr) = call_system ("mkdir $directory", $debug);

    if (!$status and ($stdout ne '' or $stderr ne '')) {
      my $error = "  > create_dir: mkdir $directory: status: $status, stdout: $stdout, stderr: $stderr\n";
      if ( $debug ) { print $error; } else { print EMAILREPORT $error; }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME [-y <year>] [-m <month>] [-d <day>] [-a <days after>] [-u <uKey>] [-D <debug>] [-V version] [-h help]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision($PROGNAME, $version);
  print "ASNMTAP Archiver for the '$APPLICATION'

-y, --year=<year> (default: current year)
-m, --month=<month> (default: current month)
-d, --day=<day> (default: current day)
-a, --daysafter=<days after> (default: 3)
-u, --uKey=<uKey plugin> (default: all plugins)
-D, --debug=F|T|L
   F(alse)  : screendebugging off (default)
   T(true)  : normal screendebugging on
   L(ong)   : long screendebugging on
-V, --version
-h, --help

Send email to $SENDEMAILTO if you have questions regarding
use of this software. To submit patches or suggest improvements, send
email to $SENDEMAILTO

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

