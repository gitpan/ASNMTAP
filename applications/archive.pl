#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/03/18, v3.000.006, archive.pl for ASNMTAP::Applications making Asnmtap v3.000.xxx compatible
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Time::Local;
use Getopt::Long;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.000.006;
use ASNMTAP::Time qw(&get_epoch &get_wday &get_yearMonthDay &get_year &get_month &get_day &get_week);

use ASNMTAP::Asnmtap::Applications v3.000.006;
use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS :ARCHIVE :DBARCHIVE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_A $opt_c $opt_r $opt_d $opt_y  $opt_D $opt_V $opt_h $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "archive.pl";
my $prgtext     = "Archiver for the '$APPLICATION'";
my $version     = '3.000.006';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $archivelist = 'ArchiveCT';               # default
my $doCgisess   = 1;                         # default
my $doReports   = 1;                         # default
my $doDatabase  = 0;                         # default
my $doYearsAgo  = -1;                        # default
my $debug       = 0;                         # default

#------------------------------------------------------------------------
# Don't edit below here unless you know what you are doing. -------------
#------------------------------------------------------------------------

my $gzipDaysAgo          = 8;                                                 # GZIP files older then n date
my $removeGzipDaysAgo    = 31;                                                # Remove files older then n days ago
my $removeAllNokDaysAgo  = 8;                                                 # Remove files older then n days ago
my $gzipDebugDaysAgo     = 3;                                                 # Remove files older then n days ago
my $removeDebugDaysAgo   = 31;                                                # Remove files older then n days ago
my $removeGzipWeeksAgo   = 53;                                                # Remove files older then n weeks ago
my $removeCgisessDaysAgo = 2;                                                 # Remove files older then n days ago
my $removeReportWeeksAgo = 53;                                                # Remove files older then n weeks ago

my $gzipEpoch            = get_epoch ('-'. $gzipDaysAgo .' days');            # GZIP files older then n date
my $removeAllNokEpoch    = get_epoch ('-'. $removeAllNokDaysAgo .' days');    # Remove files older then n days ago
my $removeGzipEpoch      = get_epoch ('-'. $removeGzipDaysAgo .' days');      # Remove files older then n days ago
my $gzipDebugEpoch       = get_epoch ('-'. $gzipDebugDaysAgo .' days');       # GZIP files older then n date
my $removeDebugEpoch     = get_epoch ('-'. $removeDebugDaysAgo .' days');     # Remove files older then n days ago
my $removeWeeksEpoch     = get_epoch ('-'. $removeGzipWeeksAgo .' weeks');    # Remove files older then n weeks ago
my $removeCgisessEpoch   = get_epoch ('-'. $removeCgisessDaysAgo .' days');   # Remove files older then n days ago
my $removeReportsEpoch   = get_epoch ('-'. $removeReportWeeksAgo .' weeks');  # Remove files older then n weeks ago
my $firstDayOfWeekEpoch  = get_epoch ('-'. (get_wday ('yesterday')).' days'); # First day current week epoch date
my $yesterdayEpoch       = get_epoch ('yesterday');                           # Yesterday epoch date
my $currentEpoch         = get_epoch ('today');                # time()       # Current epoch date

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');

GetOptions (
  "A:s" => \$opt_A, "archivelist:s" => \$opt_A,
  "c:s" => \$opt_c, "cgisess:s"     => \$opt_c,
  "r:s" => \$opt_r, "reports:s"     => \$opt_r,
  "d:s" => \$opt_d, "database:s"    => \$opt_d,
  "y:s" => \$opt_y, "yearsago:s"    => \$opt_y,
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "D:s" => \$opt_D, "debug:s"       => \$opt_D,
  "V"   => \$opt_V, "version"       => \$opt_V,
  "h"   => \$opt_h, "help"          => \$opt_h
);

if ($opt_V) { print_revision($PROGNAME, $version); exit $ERRORS{OK}; }
if ($opt_h) { print_help(); exit $ERRORS{OK}; }
if ($opt_A) { $archivelist = $1 if ($opt_A =~ /([-.A-Za-z0-9]+)/); }

if ($opt_c) {
  if ($opt_c eq 'F' || $opt_c eq 'T') {
    $doCgisess = ($opt_c eq 'F') ? 0 : 1;
  } else {
    usage("Invalid cgisess: $opt_c\n");
  }
}

if ($opt_r) {
  if ($opt_r eq 'F' || $opt_r eq 'T') {
    $doReports = ($opt_r eq 'F') ? 0 : 1;
  } else {
    usage("Invalid reports: $opt_r\n");
  }
}

if ($opt_d) {
  if ($opt_d eq 'F' || $opt_d eq 'T') {
    $doDatabase = ($opt_d eq 'F') ? 0 : 1;
  } else {
    usage("Invalid database: $opt_d\n");
  }
}

if ($opt_y) {
  if ($opt_y eq 'c') {
    $doYearsAgo = 0;
  } elsif ($opt_y >= 0 and $opt_y < 10) {
    $doYearsAgo = $opt_y;
  } else {
    usage("Invalid yearsago: $opt_y\n");
  }
}

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

my @archivelisttable;

if ( $debug ) {
  print "Current day                     : <", scalar(localtime($currentEpoch)), "><", $currentEpoch, ">\n";
  print "Yesterday                       : <", scalar(localtime($yesterdayEpoch)), "><", $yesterdayEpoch, ">\n";
  print "First day of yesterday week     : <", scalar(localtime($firstDayOfWeekEpoch)), "><", $firstDayOfWeekEpoch, ">\n";
  print "GZIP not debug files older then : <", scalar(localtime($gzipEpoch)), "><", $gzipEpoch, ">\n";
  print "GZIP debug files older then     : <", scalar(localtime($gzipDebugEpoch)), "><", $gzipDebugEpoch, ">\n";
  print "Remove All/Nok files older then : <", scalar(localtime($removeAllNokEpoch)), "><", $removeAllNokEpoch, ">\n";
  print "Remove GZIP files older then    : <", scalar(localtime($removeGzipEpoch)), "><", $removeGzipEpoch, ">\n";
  print "Remove Debug files older then   : <", scalar(localtime($removeDebugEpoch)), "><", $removeDebugEpoch, ">\n";
  print "Remove Week files older then    : <", scalar(localtime($removeWeeksEpoch)), "><", $removeWeeksEpoch, ">\n";
  print "Remove Cgisess files older then : <", scalar(localtime($removeCgisessEpoch)), "><", $removeCgisessEpoch, ">\n";
  print "Remove Report files older then  : <", scalar(localtime($removeReportsEpoch)), "><", $removeReportsEpoch, ">\n";
}

my ($emailReport, $rvOpen) = init_email_report (*EMAILREPORT, "archiverEmailReport.txt", $debug);

if ( $rvOpen ) {
  @archivelisttable = read_table($prgtext, $archivelist, 0, $debug);
  doBackupCsvSqlErrorWeekDebugReport ($RESULTSPATH, $DEBUGDIR, $REPORTDIR, $gzipEpoch, $removeAllNokEpoch, $removeGzipEpoch, $removeDebugEpoch, $removeReportsEpoch, $removeWeeksEpoch, $firstDayOfWeekEpoch, $yesterdayEpoch, $currentEpoch) if ($doReports);

  createCommentsAndEventsArchiveTables ( "-$doYearsAgo year" ) if ($doYearsAgo != -1);

  if ($doDatabase) {
    my $month = get_month ('today');
    my $day   = get_day   ('today');
    createCommentsAndEventsArchiveTables ( '-1 year' ) if ($month == 12 and $day >= 24);
    archiveCommentsAndEventsTables ( '-14 days', '-1 year' );
  }

  removeCgisessFiles ($removeCgisessEpoch) if ($doCgisess);

  my $emailreport = "\nRemove *.MySQL-sql-error.txt:\n-----------------------------\n";
  if ( $debug ) { print "$emailreport"; } else { print EMAILREPORT "$emailreport"; }

  my @sqlErrorTxtFiles = glob("$RESULTSPATH/*-MySQL-sql-error.txt");

  foreach my $sqlErrorTxtFile (@sqlErrorTxtFiles) {
    print EMAILREPORT "E- unlink <$sqlErrorTxtFile>\n";
    unlink ($sqlErrorTxtFile);
  }
} else {
  print "Cannot open $emailReport to print email report information\n";
}

my ($rc) = send_email_report (*EMAILREPORT, $emailReport, $rvOpen, $prgtext, $debug);
exit;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub archiveCommentsAndEventsTables {
  my ($eventsAgo, $commentsAgo) =  @_;

  print EMAILREPORT "\nArchive '$SERVERTABLCOMMENTS' and '$SERVERTABLEVENTS' tables:\n--------------------------------------------------\n" unless ( $debug );

  # Init parameters
  my ($rv, $dbh, $sth, $sql, $year, $month, $day, $timeslot, $yearMOVE, $monthMOVE, $sqlMOVE);

  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = errorTrapDBI("Cannot connect to the database", $debug); 

  if ($dbh and $rv) {
    $year  = get_year  ($eventsAgo);
    $month = get_month ($eventsAgo);
    $day   = get_day   ($eventsAgo);

    $timeslot = timelocal ( 0, 0, 0, $day, ($month-1), ($year-1900) );

    $sql = "select * from $SERVERTABLEVENTS force index (key_timeslot) where timeslot < '" .$timeslot. "'";

    if ($debug) {
      print "\nTable: '$SERVERTABLEVENTS', Year: '$year', Month: '$month', Day: '$day', Timeslot: '$timeslot', Date: " .scalar(localtime($timeslot)). "\n<$sql>\n";

    } else {
      print EMAILREPORT "\nTable: '$SERVERTABLEVENTS', Year: '$year', Month: '$month', Day: '$day', Timeslot: '$timeslot'\n";
    }

    $sth = $dbh->prepare($sql) or $rv = errorTrapDBI("dbh->prepare: $sql", $debug);
    $rv  = $sth->execute() or $rv = errorTrapDBI("sth->execute: $sql", $debug) if $rv;

    if ( $rv ) {
      while (my $ref = $sth->fetchrow_hashref()) {
        ($yearMOVE, $monthMOVE, undef) = split (/-/, $ref->{endDate});
        print "\n", $ref->{id}, " ", $ref->{uKey}, " ", $ref->{startDate}, " ", $ref->{endDate}, " ",$ref->{timeslot}, " \n" if ($debug);
        $sqlMOVE = 'INSERT INTO `' .$SERVERTABLEVENTS. '_' .$yearMOVE. '_' .$monthMOVE. '` SELECT * FROM `' .$SERVERTABLEVENTS. '` WHERE id = "' .$ref->{id}. '"';
        print "$sqlMOVE\n" if ($debug);
        $dbh->do( $sqlMOVE ) or $rv = errorTrapDBI("Cannot dbh->do: $sql", $debug) unless ( $debug );
        $sqlMOVE = 'DELETE FROM `' .$SERVERTABLEVENTS. '` WHERE id = "' .$ref->{id}. '"';
        print "$sqlMOVE\n" if ($debug);
        $dbh->do( $sqlMOVE ) or $rv = errorTrapDBI("Cannot dbh->do: $sql", $debug) unless ( $debug );
      }

      $sth->finish() or $rv = errorTrapDBI("sth->finish", $debug);
    }

    $year  = get_year  ($commentsAgo);
    $month = get_month ($commentsAgo);
    $day   = get_day   ($commentsAgo);

    $timeslot = timelocal ( 0, 0, 0, $day, ($month-1), ($year-1900) );

    $sql = "select * from $SERVERTABLCOMMENTS force index (solvedTimeslot) where problemSolved = '1' and solvedTimeslot < '" .$timeslot. "'";

    if ($debug) {
      print "\nTable: '$SERVERTABLCOMMENTS', Year: '$year', Month: '$month', Day: '$day', Timeslot: '$timeslot', Date: " .scalar(localtime($timeslot)). "\n<$sql>\n";
    } else {
      print EMAILREPORT "\nTable: '$SERVERTABLCOMMENTS', Year: '$year', Month: '$month', Day: '$day', Timeslot: '$timeslot'\n";
    }

    $sth = $dbh->prepare($sql) or $rv = errorTrapDBI("dbh->prepare: $sql", $debug);
    $rv  = $sth->execute() or $rv = errorTrapDBI("sth->execute: $sql", $debug) if $rv;

    if ( $rv ) {
      while (my $ref = $sth->fetchrow_hashref()) {
        ($yearMOVE, undef, undef) = split (/-/, $ref->{solvedDate});
        print "\n", $ref->{id}, " ", $ref->{uKey}, " ", $ref->{solvedDate}, " ", $ref->{solvedTimeslot}, "\n" if ($debug);
        $sqlMOVE = 'INSERT INTO `' .$SERVERTABLCOMMENTS. '_' .$yearMOVE. '` SELECT * FROM `' .$SERVERTABLCOMMENTS. '` WHERE id = "' .$ref->{id}. '"';
        print "$sqlMOVE\n" if ($debug);
        $dbh->do( $sqlMOVE ) or $rv = errorTrapDBI("Cannot dbh->do: $sql", $debug) unless ( $debug );
        $sqlMOVE = 'DELETE FROM `' .$SERVERTABLCOMMENTS. '` WHERE id = "' .$ref->{id}. '"';
        print "$sqlMOVE\n" if ($debug);
        $dbh->do( $sqlMOVE ) or $rv = errorTrapDBI("Cannot dbh->do: $sql", $debug) unless ( $debug );
      }

      $sth->finish() or $rv = errorTrapDBI("sth->finish", $debug);
    }

    $dbh->disconnect or $rv = errorTrapDBI("Sorry, the database was unable to add your entry.", $debug);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub checkTableDBI {
  my ($dbh, $database, $table, $op, $msg_type, $msg_text) = @_;

  print "-> <$database.$table>, <$op>, <$msg_type>, <$msg_text>\n" if ($debug);

  my ($Table, $Op, $Msg_type, $Msg_text) = '';
  my $rv = 1;

  my $sql = "check table $table";
  my $sth = $dbh->prepare($sql) or $rv = errorTrapDBI("dbh->prepare: $sql", $debug);
  $rv = $sth->execute() or $rv = errorTrapDBI("sth->execute: $sql", $debug) if $rv;

  if ( $rv ) {
    while (my $ref = $sth->fetchrow_hashref()) {
      $Table    = $ref->{Table};
      $Op       = $ref->{Op};
      $Msg_type = $ref->{Msg_type};
      $Msg_text = $ref->{Msg_text};
      print "<- <$Table>, <$Op>, <$Msg_type>, <$Msg_text>\n" if ($debug);
    }

    $sth->finish() or $rv = errorTrapDBI("sth->finish", $debug);
    $rv = ($rv and "$database.$table" eq $Table and $op eq $Op and $msg_type eq $Msg_type and $msg_text eq $Msg_text) ? 1 : 0;
  }

  return ($rv);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createCommentsAndEventsArchiveTables {
  my ($daysBefore) =  @_;

  print EMAILREPORT "\nCreate '$SERVERTABLCOMMENTS' and '$SERVERTABLEVENTS' tables when needed:\n--------------------------------------------------\n" unless ( $debug );

  # Init parameters
  my ($rv, $dbh, $sql, $year, $month);
  $year = get_year  ($daysBefore);

  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = errorTrapDBI("Cannot connect to the database", $debug);

  if ($dbh and $rv) {
    foreach $month ('01'..'12') {
      # $sql = "CREATE TABLE IF NOT EXISTS `". $SERVERTABLEVENTS .'_'. $year .'_'. $month ."` ( LIKE `$SERVERTABLEVENTS` )";

      $sql = "CREATE TABLE IF NOT EXISTS `". $SERVERTABLEVENTS .'_'. $year .'_'. $month ."` (
  `id` int(11) NOT NULL auto_increment,
  `uKey` varchar(11) NOT NULL default '',
  `test` varchar(100) NOT NULL default '',
  `title` varchar(75) NOT NULL default '',
  `status` varchar(9) NOT NULL default '',
  `startDate` date NOT NULL default '0000-00-00',
  `startTime` time NOT NULL default '00:00:00',
  `endDate` date NOT NULL default '0000-00-00',
  `endTime` time NOT NULL default '00:00:00',
  `duration` time NOT NULL default '00:00:00',
  `statusMessage` varchar(254) NOT NULL default '',
  `step` smallint(6) NOT NULL default '0',
  `timeslot` varchar(10) NOT NULL default '',
  `persistent` tinyint(1) NOT NULL default '9',
  `downtime` tinyint(1) NOT NULL default '9',
  `filename` varchar(254) default '',
  PRIMARY KEY  (`id`),
  KEY `key_timeslot` (`timeslot`),
  KEY `key_status` (`status`),
  KEY `idx_persistent` (`persistent`),
  KEY `key_startTime` (`startTime`),
  KEY `idx_downtime` (`downtime`),
  KEY `key_endDate` (`endDate`),
  KEY `key_test` (`test`),
  KEY `key_startDate` (`startDate`),
  KEY `uKey` (`uKey`),
  KEY `key_endTime` (`endTime`)
) TYPE=InnoDB";

      $rv = checkTableDBI ($dbh, $DATABASE, $SERVERTABLEVENTS .'_'. $year .'_'. $month, 'check', 'error', "Table '$DATABASE.". $SERVERTABLEVENTS .'_'. $year .'_'. $month ."' doesn't exist");

      if ($rv) {
        if ($debug) {
          print "\nTable: '$SERVERTABLEVENTS', Year: '$year', Month: '$month'\n<$sql>\n";
        } else {
          print EMAILREPORT "\nTable: '$SERVERTABLEVENTS', Year: '$year', Month: '$month', Status: ";
          $dbh->do( $sql ) or $rv = errorTrapDBI("Cannot dbh->do: $sql", $debug);
          $rv = checkTableDBI ($dbh, $DATABASE, $SERVERTABLEVENTS .'_'. $year .'_'. $month, 'check', 'status', 'OK');
          if ($rv) { print EMAILREPORT "Created\n\n"; } else { print EMAILREPORT "NOT CREATED, PLEASE VERIFY\n\n"; }
        }
      } else {
        print "Table: '$SERVERTABLEVENTS', Year: '$year', Month: '$month', Status: ALREADY CREATED\n\n" if ($debug);
      }
    }

    # $sql = "CREATE TABLE IF NOT EXISTS `". $SERVERTABLCOMMENTS .'_'. $year ."` ( LIKE `$SERVERTABLCOMMENTS` )";

    $sql = "CREATE TABLE IF NOT EXISTS `". $SERVERTABLCOMMENTS .'_'. $year ."` (
  `id` int(11) NOT NULL auto_increment,
  `uKey` varchar(11) NOT NULL default '',
  `title` varchar(75) NOT NULL default '',
  `remoteUser` varchar(11) NOT NULL default '',
  `persistent` tinyint(1) NOT NULL default '0',
  `downtime` tinyint(1) NOT NULL default '0',
  `entryDate` date NOT NULL default '0000-00-00',
  `entryTime` time NOT NULL default '00:00:00',
  `entryTimeslot` varchar(10) NOT NULL default '0000000000',
  `activationDate` date NOT NULL default '0000-00-00',
  `activationTime` time NOT NULL default '00:00:00',
  `activationTimeslot` varchar(10) NOT NULL default '0000000000',
  `suspentionDate` date NOT NULL default '0000-00-00',
  `suspentionTime` time NOT NULL default '00:00:00',
  `suspentionTimeslot` varchar(10) NOT NULL default '9999999999',
  `solvedDate` date NOT NULL default '0000-00-00',
  `solvedTime` time NOT NULL default '00:00:00',
  `solvedTimeslot` varchar(10) NOT NULL default '0000000000',
  `problemSolved` tinyint(1) NOT NULL default '1',
  `commentData` blob NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `activationTimeslot` (`activationTimeslot`),
  KEY `entryTimeslot` (`entryTimeslot`),
  KEY `suspentionTimeslot` (`suspentionTimeslot`),
  KEY `persistent` (`persistent`),
  KEY `problemSolved` (`problemSolved`),
  KEY `downtime` (`downtime`),
  KEY `solvedTimeslot` (`solvedTimeslot`),
  KEY `uKey` (`uKey`),
  KEY `remoteUser` (`remoteUser`)
) TYPE=InnoDB";

    $rv = checkTableDBI ($dbh, $DATABASE, $SERVERTABLCOMMENTS .'_'. $year, 'check', 'error', "Table '$DATABASE.". $SERVERTABLCOMMENTS .'_'. $year ."' doesn't exist");

    if ($rv) {
      if ($debug) {
        print "\nTable: '$SERVERTABLCOMMENTS', Year: '$year'\n<$sql>\n";
      } else {
        print EMAILREPORT "\nTable: '$SERVERTABLCOMMENTS', Year: '$year', Status: ";
        $dbh->do( $sql ) or $rv = errorTrapDBI("Cannot dbh->do: $sql", $debug);
        $rv = checkTableDBI ($dbh, $DATABASE, $SERVERTABLCOMMENTS .'_'. $year, 'check', 'status', 'OK');
        if ($rv) { print EMAILREPORT "Created\n\n"; } else { print EMAILREPORT "NOT CREATED, PLEASE VERIFY\n\n"; }
      }
    } else {
      print "Table: '$SERVERTABLCOMMENTS', Year: '$year', Status: ALREADY CREATED\n\n" if ($debug);
    }

    $dbh->disconnect or $rv = errorTrapDBI("Sorry, the database was unable to add your entry.", $debug);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub doBackupCsvSqlErrorWeekDebugReport {
  my ($RESULTSPATH, $DEBUGDIR, $REPORTDIR, $gzipEpoch, $removeAllNokEpoch, $removeGzipEpoch, $removeDebugEpoch, $removeReportsEpoch, $removeWeeksEpoch, $firstDayOfWeekEpoch, $yesterdayEpoch, $currentEpoch) =  @_;

  print EMAILREPORT "\nDo backup, csv, sql, error, week, and debug files:\n--------------------------------------------------\n" unless ( $debug );
  my ($darchivelist, $dtest, $pagedir, $ttest, $command, $rvOpendir, $path, $filename, $debugPath, $debugFilename, $reportPath, $reportFilename, $weekFilename);
  my @files = ();

  foreach $darchivelist (@archivelisttable) {
    ($pagedir, $ttest) = split(/\#/, $darchivelist, 2);
    my @stest = split(/\|/, $ttest);

    $path = $RESULTSPATH .'/'. $pagedir;
    $debugPath = $path .'/'. $DEBUGDIR;
    $reportPath = $path .'/'. $REPORTDIR;

    if ($debug) {
      print "\n", "<$RESULTSPATH><$pagedir><$path><$DEBUGDIR><$REPORTDIR>\n" 
    } else {
      print EMAILREPORT "\nPlugin: '$ttest', results directory: '$path'\n";
    }

    $rvOpendir = opendir(DIR, $path);

    if ($rvOpendir) {
      @files = readdir(DIR);
      closedir(DIR);
    }

    if (-e $debugPath) {
      $rvOpendir = opendir(DIR, $debugPath);

      if ($rvOpendir) {
        while ($debugFilename = readdir(DIR)) {
          print "Debug Filename: <$debugFilename>\n" if ($debug >= 2);
          gzipOrRemoveHttpDumpDebug ($gzipDebugEpoch, $removeDebugEpoch, $debugPath, $debugFilename);
        }

        closedir(DIR);
      }
    }

    if (-e $reportPath) {
      $rvOpendir = opendir(DIR, $reportPath);

      if ($rvOpendir) {
        while ($reportFilename = readdir(DIR)) {
          print "Report Filename: <$reportFilename>\n" if ($debug >= 2);
          removeOldReportFiles ($removeReportsEpoch, $removeGzipEpoch, $reportPath, $reportFilename);
        }

        closedir(DIR);
      }
    }

    foreach $dtest (@stest) {
      my ($uKey, $test) = split(/\#/, $dtest);

      ($command, undef) = split(/\.pl/, $test);
      my ( $tWeek, $tYear ) = get_week('yesterday');
      $weekFilename = get_year('yesterday') ."w$tWeek-$command-$uKey-csv-week.txt";
      if (-e "$path/$weekFilename") { unlink ($path.'/'.$weekFilename); }
      print "Test          : <$dtest>\n" if ($debug);

      foreach $filename (@files) {
        print "Filename      : <$filename>\n" if ($debug >= 2);
        catAllCsvFilesYesterdayWeek ($firstDayOfWeekEpoch, $yesterdayEpoch, $uKey, $command, $path, $weekFilename, $filename);
        removeAllNokgzipCsvSqlErrorWeekFilesOlderThenAndMoveToBackupShare ($gzipEpoch, $removeAllNokEpoch, $removeGzipEpoch, $removeDebugEpoch, $removeWeeksEpoch, $uKey, $command, $path, $filename);
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub removeAllNokgzipCsvSqlErrorWeekFilesOlderThenAndMoveToBackupShare {
  my ($gzipEpoch, $removeAllNokEpoch, $removeGzipEpoch, $removeDebugEpoch, $removeWeeksEpoch, $uKey, $command, $path, $filename) =  @_;

  my ($datum, $staart) = split(/\-/, $filename, 2);

  if ( $staart ) {
    if ( $staart eq "all.txt" ) {
      if ($datum le get_yearMonthDay($removeAllNokEpoch)) {
        if ($debug) {
          print "A- <$datum><", get_yearMonthDay($removeAllNokEpoch), "><$path><$filename>\n";
        } else {
          print EMAILREPORT "A- <$datum><", get_yearMonthDay($removeAllNokEpoch), "> unlink <$path><$filename>\n";
          unlink ($path.'/'.$filename);
        }
      }
    } elsif ( $staart eq "$command-$uKey-csv.txt" ) {
      if ($datum le get_yearMonthDay($gzipEpoch)) {
	    if ($debug) {
          print "C+ <$datum><", get_yearMonthDay($gzipEpoch), "><$path><$filename>\n";
        } else {
          print EMAILREPORT "C+ <$datum><", get_yearMonthDay($gzipEpoch), "> gzip <$path><$filename>\n";
          my ($status, $stdout, $stderr) = call_system ('gzip --force '.$path.'/'.$filename, $debug);
          print EMAILREPORT "C+  E R R O R: <$stderr>\n" unless ( $status );
        }
      }
    } elsif ( $staart eq "$command-$uKey-csv.txt.gz" ) {
      if ($datum le get_yearMonthDay($removeGzipEpoch)) {
	    if ($debug) {
          print "C- <$datum><", get_yearMonthDay($removeGzipEpoch), "><$path><$filename>\n";
        } else {
          print EMAILREPORT "C- <$datum><", get_yearMonthDay($removeGzipEpoch), "> unlink <$path><$filename>\n";
          unlink ($path.'/'.$filename);
        }
      }
    } elsif ( $staart eq "$command-$uKey-csv-week.txt" ) {
      my ($jaar, $week) = split(/w/, $datum);
      my $jaarWeekFilename  = int($jaar.$week);
      my ( $tWeek, $tYear ) = get_week ('yesterday');
      my $jaarWeekYesterday = int(get_year('yesterday'). $tWeek);

      if ( $jaarWeekFilename lt $jaarWeekYesterday ) {
	    if ($debug) {
          print "CW+<$jaarWeekYesterday><$jaarWeekFilename><$path><$filename>\n";
        } else {
          print EMAILREPORT "CW+<$jaarWeekYesterday><$jaarWeekFilename> gzip <$path><$filename>\n";
          my ($status, $stdout, $stderr) = call_system ('gzip --force '.$path.'/'.$filename, $debug);
          print EMAILREPORT "CW+  E R R O R: <$stderr>\n" unless ( $status );
        }
      }
    } elsif ( $staart eq "$command-$uKey-csv-week.txt.gz" ) {
      my ($jaar, $week) = split(/w/, $datum);
      my $jaarWeekFilename = int($jaar.$week);
      my ( $tWeek, $tYear ) = get_week ('-'. $removeGzipWeeksAgo. ' weeks');
      my $jaarWeekRemove   = int(get_year('-'. $removeGzipWeeksAgo. ' weeks') .$tWeek);

      if ( $jaarWeekFilename le $jaarWeekRemove ) {
		if ($debug) {
          print "CW-<$jaarWeekRemove><$jaarWeekFilename><", get_yearMonthDay($removeWeeksEpoch), "<$path><$filename>\n";
        } else {
          print EMAILREPORT "CW-<$jaarWeekRemove><$jaarWeekFilename><", get_yearMonthDay($removeWeeksEpoch), " unlink <$path><$filename>\n";
          unlink ($path.'/'.$filename);
        }
      }
    } elsif ( $staart eq "$command-$uKey.sql" ) {
      if ($debug) {
        print "S+ <$datum><", get_yearMonthDay($gzipEpoch), "><$path><$filename>\n" if ($datum le get_yearMonthDay($gzipEpoch));
      } else {
        # Init parameters
        my ($rv, $dbh, $sql);

        # open connection to database and query data
        $rv  = 1;
        $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = errorTrapDBI("Cannot connect to the database", $debug);

        if ($dbh and $rv) {
          $sql = "LOAD DATA LOW_PRIORITY LOCAL INFILE '$path/$filename' INTO TABLE $SERVERTABLEVENTS FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\\n'";
          $dbh->do( $sql ) or $rv = errorTrapDBI("Cannot dbh->do: $sql", $debug);

          if ( $rv ) {
            my $mysqlInfo = $dbh->{mysql_info};
            my ($records, $deleted, $skipped, $warnings) = ($mysqlInfo =~ /^Records:\s+(\d+)\s+Deleted:\s+(\d+)\s+Skipped:\s+(\d+)\s+Warnings: (\d+)$/);

            if ($deleted eq '0' and $skipped eq '0' and $warnings eq '0') {
              print EMAILREPORT "S+ LOAD DATA ... : $records record(s) added for $filename\n";
              my ($status, $stdout, $stderr) = call_system ('gzip --force '.$path.'/'.$filename, $debug);
              print EMAILREPORT "S+  E R R O R: <$stderr>\n" unless ( $status );
            } else {
              print EMAILREPORT "S+ LOAD DATA ... WARNING for $filename: $mysqlInfo, <$records> <$deleted> <$skipped> <$warnings>\n";
              rename("$path/$filename", "$path/$filename-LOAD-DATA-FAILED");
            }
          }

          $dbh->disconnect or $rv = errorTrapDBI("Sorry, the database was unable to add your entry.", $debug);
        }
      }
    } elsif ( $staart eq "$command-$uKey.sql.gz" ) {
      if ($datum le get_yearMonthDay($removeGzipEpoch)) {
	    if ($debug) {
          print "S- <$datum><", get_yearMonthDay($removeGzipEpoch), "><$path><$filename>\n";
        } else {
          print EMAILREPORT "S- <$datum><", get_yearMonthDay($removeGzipEpoch), "> unlink <$path><$filename>\n";
          unlink ($path.'/'.$filename);
        }
      }
    } elsif ( $staart eq "$command-$uKey-sql-error.txt" ) {
      if ($datum le get_yearMonthDay($removeGzipEpoch)) {
	    if ($debug) {
          print "SE-<$datum><", get_yearMonthDay($removeDebugEpoch), "><$path><$filename>\n";
        } else {
          print EMAILREPORT "SE-<$datum><", get_yearMonthDay($removeDebugEpoch), "> unmink <$path><$filename>\n";
          unlink ($path.'/'.$filename);
        }
      }
    } elsif ( $staart eq "nok.txt" ) {
      if ($datum le get_yearMonthDay($removeAllNokEpoch)) {
	    if ($debug) {
          print "N- <$datum><", get_yearMonthDay($removeAllNokEpoch), "><$path><$filename>\n";
        } else {
          print EMAILREPORT "N- <$datum><", get_yearMonthDay($removeAllNokEpoch), "> unlink <$path><$filename>\n";
          unlink ($path.'/'.$filename);
        }
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub catAllCsvFilesYesterdayWeek {
  my ($firstDayOfWeekEpoch, $yesterdayEpoch, $uKey, $command, $path, $weekFilename, $filename) =  @_;

  for (my $loop = $firstDayOfWeekEpoch; $loop <= $yesterdayEpoch; $loop += 86400) {
    if ($filename eq get_yearMonthDay($loop)."-$command-$uKey-csv.txt") {
      my $rvOpen = open(CAT, ">>$path/$weekFilename");

      if ($rvOpen) {
        $rvOpen = open(CSV, "$path/$filename");

        if ($rvOpen) {
          while (<CSV>) {
            chomp;

            unless ( /^#/ ) {
              my $dummy = $_;
              $dummy =~ s/\ {1,}//g;
              if ($dummy ne '') { print CAT $_, "\n"; }
            }
          }

          close(CSV);
          my ( $tWeek, $tYear ) = get_week ('today');
          print "WF <week$tWeek><$filename>\nW  <$path/$weekFilename>\n" if ($debug);
        } else {
          print "Cannot open $filename!\n";
        }

        close(CAT);
      } else {
        print "Cannot open $filename!\n";
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub gzipOrRemoveHttpDumpDebug {
  my ($gzipDebugEpoch, $removeDebugEpoch, $debugPath, $debugFilename) = @_;

  my ($suffix, $extentie, $datum, $restant);

  print "<$debugFilename>\n" if ($debug);

  ($suffix, $extentie) = split(/\./, $debugFilename, 2);
  ($datum, $restant) = split(/\-/, $suffix, 2);

  if (defined $restant) {
    $datum = substr($datum, 0, 8);

    if ( $extentie ) {
      if ( $extentie eq 'htm' ) {
        if ($datum le get_yearMonthDay($gzipDebugEpoch)) {
          if ($debug) {
            print "HT+<$datum><".get_yearMonthDay($gzipDebugEpoch)."><$debugPath><$debugFilename>\n";
          } else {
            print EMAILREPORT "HT+<$datum><".get_yearMonthDay($gzipDebugEpoch)."> gzip <$debugPath><$debugFilename>\n";
            my ($status, $stdout, $stderr) = call_system ('gzip --force '.$debugPath.'/'.$debugFilename, $debug);
            print EMAILREPORT "HT+  E R R O R: <$stderr>\n" unless ( $status );
          }
        }
      } elsif ( $extentie eq 'htm.gz' ) {
        if ($datum le get_yearMonthDay($removeDebugEpoch)) {
    	  if ($debug) {
            print "HT-<$datum><".get_yearMonthDay($removeDebugEpoch)."><$debugPath><$debugFilename>\n";
          } else {
            print EMAILREPORT "HT-<$datum><".get_yearMonthDay($removeDebugEpoch)."> unlink <$debugPath><$debugFilename>\n";
            unlink ($debugPath.'/'.$debugFilename);
          }
        }
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub removeCgisessFiles {
  my ($removeCgisessEpoch) = @_;

  my $emailreport = "\nRemove cgisess files:\n---------------------\n";
  if ( $debug ) { print "$emailreport"; } else { print EMAILREPORT "$emailreport"; }

  my @cgisessPathFilenames = glob("$CGISESSPATH/cgisess_*");

  foreach my $cgisessPathFilename (@cgisessPathFilenames) {
    my (undef, $cgisessFilename) = split (/^$CGISESSPATH\//, $cgisessPathFilename);
    my (undef, $sessionID) = split (/^cgisess_/, $cgisessFilename);
    print "Filename      : <$cgisessFilename><$sessionID>\n" if ($debug >= 2);
    my ($sessionExists, %session) = get_session_param ($sessionID, $CGISESSPATH, $cgisessFilename, $debug);

    if ( $sessionExists ) {
      if (defined $session{ASNMTAP}) {
        if ($session{ASNMTAP} eq 'LEXY') {
          print "              : <$removeCgisessEpoch><" .$session{_SESSION_CTIME}. ">\n" if ($debug >= 2);

          if ($removeCgisessEpoch > $session{_SESSION_CTIME}) {
            if ($debug) {
              print "CS <$cgisessPathFilename><" .$session{_SESSION_CTIME}. ">\n";
            } else {
              print EMAILREPORT "CS unlink <$cgisessPathFilename><" .$session{_SESSION_CTIME}. ">\n";
              unlink ($cgisessPathFilename);
            }
          } else {
            print "CS-<$cgisessPathFilename><$removeCgisessEpoch><" .$session{_SESSION_CTIME}. ">\n" if ($debug >= 2);
          }
        } else {
          print "CS-<$cgisessPathFilename> ASNMTAP not LEXY>\n" if ($debug >= 2);
        }
      } else {
        if ($removeCgisessEpoch > $session{_SESSION_CTIME}) {
          if ($debug) {
            print "CS <$cgisessPathFilename><" .$session{_SESSION_CTIME}. ">\n";
          } else {
            print EMAILREPORT "CS unlink <$cgisessPathFilename><" .$session{_SESSION_CTIME}. ">\n";
            unlink ($cgisessPathFilename);
          }
        } else {
          print "CS-<$cgisessPathFilename> ASNMTAP not LEXY>\n" if ($debug >= 2);
        }
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub removeOldReportFiles {
  my ($removeReportsEpoch, $removeGzipEpoch, $reportPath, $reportFilename) = @_;

  my ($suffix, $prefix, $datum, $plugin, $restant, $extentie);
  ($suffix, $prefix) = split(/\.pl/, $reportFilename, 2);
  ($datum, $plugin) = split(/\-/, $suffix, 2) if (defined $suffix);
  ($restant, $extentie) = split(/\./, $prefix, 2) if (defined $prefix);

  if ($debug) {
    print "<$reportFilename>";

    if ($debug >= 2) {
      print " S <$suffix>, P <$prefix>" if (defined $prefix);
      print " D <$datum>, P <$plugin>" if (defined $plugin);
      print " R <$restant>, E <$extentie>" if (defined $extentie);
    }

    print "\n";
  }
	
  if (defined $restant) {
    $datum = substr($datum, 0, 8);

    if ($extentie eq 'pdf') {
      if ($datum le get_yearMonthDay($removeReportsEpoch)) {
        if ($debug) {
          print "RP-<$datum><".get_yearMonthDay($removeReportsEpoch)."><$reportPath><$reportFilename>\n";
        } else {
          print EMAILREPORT "RP-<$datum><".get_yearMonthDay($removeReportsEpoch)."> unlink <$reportPath><$reportFilename>\n";
          unlink ($reportPath.'/'.$reportFilename);
        }
      } elsif ($restant =~ /\-Day_\w+\-id_\d+$/) {
        if ($datum le get_yearMonthDay($removeGzipEpoch)) {
          if ($debug) {
            print "RP-<$datum><".get_yearMonthDay($removeReportsEpoch)."><$reportPath><$reportFilename>\n";
          } else {
            print EMAILREPORT "RP-<$datum><".get_yearMonthDay($removeReportsEpoch)."> unlink <$reportPath><$reportFilename>\n";
            unlink ($reportPath.'/'.$reportFilename);
          }
        }
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($error_message, $debug) = @_;

  print EMAILREPORT "   DBI Error:\n", $error_message, "\nERROR: $DBI::err ($DBI::errstr)\n";
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME [-A <archivelist>] [-c F|T] [-r F|T] [-d F|T] [-y <years ago>] [-D <debug>] [-V version] [-h help]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision($PROGNAME, $version);
  print "ASNMTAP Archiver for the '$APPLICATION'

-A, --archivelist=<filename>
   FILENAME : filename from the archivelist for the html output loop (default 'ArchiveCT')
-c, --cgisess=F|T
   F(alse)  : don't remove the cgisess files
   T(true)  : remove the cgisess files (default)
-r, --reports=F|T
   F(alse)  : don't backup Csv, Sql, Error, Week, Debug reports
   T(true)  : remove backup Csv, Sql, Error, Week, Debug reports (default)
-d, --database=F|T
   F(alse)  : don't archive the '$SERVERTABLEVENTS' and '$SERVERTABLCOMMENTS' tables (default)
   T(true)  : archive the '$SERVERTABLEVENTS' and '$SERVERTABLCOMMENTS' tables
-y, --yearsago=<years ago>
   YEARS AGO: c => current year or 1..9 => the number of years ago that the '$SERVERTABLEVENTS' 
              and '$SERVERTABLCOMMENTS' tables need to be created
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

