#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/04/xx, v3.000.007, display.pl for ASNMTAP::Asnmtap::Applications::Display making Asnmtap v3.000.xxx compatible
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Time::Local;
use Getopt::Long;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.000.007;
use ASNMTAP::Time qw(&get_datetimeSignal &get_timeslot);

use ASNMTAP::Asnmtap::Applications::Display v3.000.007;
use ASNMTAP::Asnmtap::Applications::Display qw(:APPLICATIONS :DISPLAY :DBDISPLAY);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_H $opt_V $opt_h $opt_C $opt_P $opt_D $opt_L $opt_T $opt_l $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "display.pl";
my $prgtext     = "Display for the '$APPLICATION'";
my $version     = '3.000.007';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $checklist   = "DisplayCT";                                  # default
my $htmlOutput  = $HTTPSPATH .'/nav/index/index';               # default
my $pagedir     = 'index';                                      # default
my $pageset     = 'index';                                      # default
my $debug       = 0;                                            # default
my $loop        = 0;                                            # default
my $displayTime = 1;                                            # default
my $lockMySQL   = 0;                                            # default

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $displayTimeslot = 0;           # only for extra debugging information

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');

GetOptions (
  "V"   => \$opt_V, "version"        => \$opt_V,
  "h"   => \$opt_h, "help"           => \$opt_h,
  "H=s" => \$opt_H, "hostname=s"     => \$opt_H,
  "C:s" => \$opt_C, "checklist:s"    => \$opt_C,
  "P:s" => \$opt_P, "pagedir:s"      => \$opt_P,
  "D:s" => \$opt_D, "debug:s"        => \$opt_D,
  "L:s" => \$opt_L, "loop:s"         => \$opt_L,
  "T:s" => \$opt_T, "displayTime:s"  => \$opt_T,
  "l:s" => \$opt_l, "lockMySQL:s"    => \$opt_l
);

if ($opt_V) { print_revision($PROGNAME, $version); exit; }
if ($opt_h) { print_help(); exit; }

($opt_H) || usage("MySQL hostname/address not specified\n");
my $serverName = $1 if ($opt_H =~ /([-.A-Za-z0-9]+)/);
($serverName) || usage("Invalid MySQL hostname/address: $opt_H\n");

if ($opt_C) { $checklist = $1 if ($opt_C =~ /([-.A-Za-z0-9]+)/); }
if ($opt_P) { $pagedir = $opt_P; }

if ($opt_D) {
  if ($opt_D eq 'F' || $opt_D eq 'T') {
    $debug = ($opt_D eq 'F') ? 0 : 1;
  } else {
    usage("Invalid debug: $opt_D\n");
  }
}

if ($opt_L) {
  if ($opt_L eq 'F' || $opt_L eq 'T') {
    $loop = ($opt_L eq 'F') ? 0 : 1;
  } else {
    usage("Invalid loop: $opt_L\n");
  }
}

if ($opt_T) {
  if ($opt_T eq 'F' || $opt_T eq 'T') {
    $displayTime = ($opt_T eq 'F') ? 0 : 1;
  } else {
    usage("Invalid displayTime: $opt_T\n");
  }
}

if ($opt_l) {
  if ($opt_l eq 'F' || $opt_l eq 'T') {
    $lockMySQL = ($opt_l eq 'F') ? 0 : 1;
  } else {
    usage("Invalid lockMySQL: $opt_l\n");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($dchecklist, $dtest, $dfetch, $tinterval, $tgroep, $resultsdir, $ttest, $firstTimeslot, $lastTimeslot, $rvOpen);
my (@fetch, $dstart, $tstart, $start, $step, $names, $data, $rows, $columns, $line, $val, @vals);
my ($command, $tstatus, $tduration, $timeValue, $prevGroep);
my ($rv, $dbh, $sth, $lockString, $findString, $unlockString, $doChecklist, $timeCorrectie, $timeslot);
my ($groupCondensedView, $emptyFullView, $emptyCondencedView, $emptyStatusMessage, $itemCondensedView, @itemCondensedView);
my ($checkOk, $checkSkip, $printCondensedView, @printCondensedView, $problemSolved, $verifyNumber, $inProgressNumber);
my ($playSoundInProgress, $playSoundPreviousStatus, $playSoundStatus, %tableSoundStatusCache);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $boolean_daemonQuit    = 0;
my $boolean_signal_hup    = 0;
my $boolean_daemonControl = $loop;

my $colspanDisplayTime = $NUMBEROFFTESTS+2;
$colspanDisplayTime += $NUMBEROFFTESTS if $displayTime;

my $pidfile = $PIDPATH .'/'. $checklist .'.pid';

my @checklisttable = read_table($prgtext, $checklist, 1, $debug);
resultsdirCreate();

my $directory = $HTTPSPATH .'/nav/'. $pagedir;
create_dir ($directory) unless ( -e "$directory" );
$htmlOutput = $directory .'/'. $pageset;

print "$htmlOutput\n";

unless (fork) {                                  # unless ($pid = fork) {
  unless (fork) {
#   if ($boolean_daemonControl) { sleep until getppid == 1; }

    print "Main Daemon control loop for: <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
    write_pid() if ($boolean_daemonControl);

    if ($boolean_daemonControl) {
      print "Set daemon catch signals for: <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
      write_tableSoundStatusCache ($checklist, $debug);
      $SIG{HUP} = \&signalHUP;
      $SIG{QUIT} = \&signalQUIT;
      $SIG{__DIE__} = \&signal_DIE;
      $SIG{__WARN__} = \&signal_WARN;
    } else {
      $boolean_daemonQuit = 1;
    }

    do {
      # Catch signals implementation
      if ($boolean_signal_hup) {
        @checklisttable = read_table($prgtext, $checklist, 1, $debug);
        resultsdirCreate();
        $boolean_signal_hup = 0;
      }

      # Crontab implementation
      read_tableSoundStatusCache ($checklist, $debug);
      do_crontab ();
      write_tableSoundStatusCache ($checklist, $debug);
    } until ($boolean_daemonQuit);

    exit 0;
  }

  exit 0;
}

# if ($boolean_daemonControl) { waitpid($pid,0); }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub resultsdirCreate {
  foreach $dchecklist (@checklisttable) {
    my (undef, undef, $resultsdir, undef) = split(/\#/, $dchecklist, 4);
    my $logging = $RESULTSPATH .'/'. $resultsdir;
    create_dir ($logging);
    $logging .= "/";
    create_header ($logging ."HEADER.html");
    create_footer ($logging ."FOOTER.html");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub read_tableSoundStatusCache {
  my ($checklist, $debug) = @_;

  %tableSoundStatusCache = ();

  if (-e "$APPLICATIONPATH/tmp/$checklist-sound-status.cache") {
    my $rvOpen = open(READ, "$APPLICATIONPATH/tmp/$checklist-sound-status.cache");

    if ($rvOpen) {
      while (<READ>) {
        chomp;

        if ($_ ne '') {
          my ($key, $value) = split (/=>/, $_);
          $tableSoundStatusCache { $key } = $value;
        }
      }

  	  close(READ);

      if ($debug) {
        print "$APPLICATIONPATH/tmp/$checklist-sound-status.cache: READ\n";
        print "-->\n";
        while ( my ($key, $value) = each(%tableSoundStatusCache) ) { print "'$key' => '$value'\n"; }
        print "<--\n";
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub write_tableSoundStatusCache {
  my ($checklist, $debug) = @_;

  my $rvOpen = open(WRITE, ">$APPLICATIONPATH/tmp/$checklist-sound-status.cache");

  if ($rvOpen) {
    print "\n$APPLICATIONPATH/tmp/$checklist-sound-status.cache: WRITE\n-->\n" if ($debug);

    while ( my ($key, $value) = each(%tableSoundStatusCache) ) { 
      print WRITE "$key=>$value\n";
      print "'$key' => '$value'\n" if ($debug); 
    }

    close(WRITE);
    print "<--\n" if ($debug);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub do_crontab {
  $rvOpen = open(HTML, ">$htmlOutput.tmp");

  unless ( $rvOpen ) {
    print "Cannot open $htmlOutput.tmp to create the html information\n";
    exit 0;
  }

  $rvOpen = open(HTMLCV, ">$htmlOutput-cv.tmp");

  unless ( $rvOpen ) {
    print "Cannot open $htmlOutput-cv.tmp to create the html information\n";
    exit 0;
  }
	
  $prevGroep = "";
  my ($dstatusMessage, @itemStatusMessage, @printStatusMessage);
  @itemStatusMessage = @printStatusMessage = ();
  printHtmlHeader($APPLICATION);

  my $currentDate = time();

  $rv  = 1;
  $dbh = DBI->connect("DBI:mysql:$DATABASE:$serverName:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE") or $rv = errorTrapDBI($checklist, "Cannot connect to the database");

  if ($lockMySQL) {
    if ($dbh and $rv) {
      $lockString = 'LOCK TABLES ' .$SERVERTABLEVENTS. ' READ';
      $dbh->do ( $lockString ) or $rv = errorTrapDBI($checklist, "Cannot dbh->do: $lockString");
    }
  }

  $playSoundStatus = 0;
  $doChecklist = ($dbh and $rv) ? 1 : 0;
  $emptyFullView = $emptyCondencedView = $emptyStatusMessage = 1;

  if ($doChecklist) {
    $groupCondensedView = 0;
	@itemCondensedView = @printCondensedView = [];

    foreach $dchecklist (@checklisttable) {
      ($tinterval, $tgroep, $resultsdir, $ttest) = split(/\#/, $dchecklist, 4);
      my @stest = split(/\|/, $ttest);
      my $showGroepHeader = ($prevGroep ne $tgroep) ? 1 : 0;
      my $showGroepFooter = (($prevGroep ne "") && $showGroepHeader) ? 1 : 0;
      printGroepCV($prevGroep, $showGroepHeader, 1);
      $prevGroep = $tgroep;
      printGroepFooter('', $showGroepFooter);
      printGroepHeader($tgroep, $showGroepHeader);

      foreach $dtest (@stest) {
        my ($uniqueKey, $title, $test, $help) = split(/\#/, $dtest);
        my ($command, undef) = split(/\.pl/, $test);
        my $trendline = get_trendline_from_test($test);

        print "<", $tgroep, "><", $resultsdir, "><", $uniqueKey, "><", $title, "><", $test, ">\n" if ($debug);
        printItemHeader($resultsdir, $uniqueKey, $command, $title, $help);
        my $number = 1;
        my $statusIcon;

        if ($dbh and $rv) {
          my ($acked, $sql, $activationTimeslot, $suspentionTimeslot, $persistent, $downtime, $suspentionTimeslotPersistentTrue, $suspentionTimeslotPersistentFalse);
          $sql = "select activationTimeslot, suspentionTimeslot, persistent, downtime from $SERVERTABLCOMMENTS where uKey = '$uniqueKey' and problemSolved = '0' order by persistent desc";
          $sth = $dbh->prepare( $sql ) or $rv = errorTrapDBI($checklist, "Cannot dbh->prepare: $sql");
          $sth->execute or $rv = errorTrapDBI($checklist, "Cannot sth->execute: $sql") if $rv;
          $downtime = 0;

          if ( $rv ) {
            my ($TactivationTimeslot, $TsuspentionTimeslot, $Tpersistent, $Tdowntime, $firstRecordPersistentTrue, $firstRecordPersistentFalse);
            $acked = $sth->rows;
            $persistent = -1;
            $activationTimeslot = 9999999999;
            $firstRecordPersistentTrue = $firstRecordPersistentFalse = 1;
            $suspentionTimeslot = $suspentionTimeslotPersistentTrue = $suspentionTimeslotPersistentFalse = 0;

            if ( $acked ) {
              while( ($TactivationTimeslot, $TsuspentionTimeslot, $Tpersistent, $Tdowntime) = $sth->fetchrow_array() ) {
                $downtime = ($Tdowntime) ? 1 : $downtime;

                if ( $Tpersistent ) {
                  if ( $firstRecordPersistentTrue ) {
                    $persistent = 1;
                    $firstRecordPersistentTrue = 0;
                    $suspentionTimeslotPersistentTrue = int($TsuspentionTimeslot);
                  }

                  $suspentionTimeslotPersistentTrue = ($suspentionTimeslotPersistentTrue  > int($TsuspentionTimeslot)) ? $suspentionTimeslotPersistentTrue  : int($TsuspentionTimeslot);
                } else {
                  if ( $firstRecordPersistentFalse ) {
                    $persistent = $firstRecordPersistentFalse = 0;
                    $suspentionTimeslotPersistentFalse = int($TsuspentionTimeslot);
                  }

                  $suspentionTimeslotPersistentFalse = ($suspentionTimeslotPersistentFalse > int($TsuspentionTimeslot)) ? $suspentionTimeslotPersistentFalse : int($TsuspentionTimeslot);
                }

                $activationTimeslot = ($activationTimeslot < int($TactivationTimeslot)) ? $activationTimeslot : int($TactivationTimeslot);
                $suspentionTimeslot = ($suspentionTimeslot > int($TsuspentionTimeslot)) ? $suspentionTimeslot : int($TsuspentionTimeslot);
              }
            }

            $sth->finish() or $rv = errorTrapDBI($checklist, "Cannot sth->finish: $sql");
          }

          $step          = $tinterval * 60;
          $lastTimeslot  = get_timeslot ($currentDate);
          $firstTimeslot = $lastTimeslot - ($step * $NUMBEROFFTESTS);
          $timeCorrectie = 0;
          $findString    = 'select * from '.$SERVERTABLEVENTS.' force index (key_timeslot) where uKey = "'.$uniqueKey.'" and step <> "0" and (timeslot between "'.$firstTimeslot.'" and "'.$lastTimeslot.'") order by id desc';

          print "<", $findString, ">\n" if ($debug);
          $sth = $dbh->prepare($findString) or $rv = errorTrapDBI($checklist, "Cannot dbh->prepare: $findString");
          $sth->execute or $rv = errorTrapDBI($checklist, "Cannot sth->execute: $findString") if $rv;

          my (@itemStatus, @itemStarttime, @itemTimeslot, @tempStatusMessage);
          @itemStatus = @itemStarttime = @itemTimeslot = @tempStatusMessage = ();
          $timeValue = $lastTimeslot;

          for (; $number <= $NUMBEROFFTESTS; $number++) {
            push (@itemStatus, ($number == 1) ? 'IN PROGRESS' : 'NO DATA');
            push (@itemStarttime, sprintf ("%02d:%02d:%02d", (localtime($timeValue+$timeCorrectie))[2,1,0]));
            push (@itemTimeslot, $timeValue);
            push (@tempStatusMessage, undef);
            $timeValue -= $step;
          }

          $timeValue = $lastTimeslot;

          if ($rv) {
            while (my $ref = $sth->fetchrow_hashref()) {
              $timeslot = int(($lastTimeslot - $ref->{timeslot}) / $step);
              print "<", $timeslot, "><", $ref->{title}, "><", $ref->{startTime}, "><", $ref->{timeslot}, ">\n" if ($debug);

              if ($timeslot >= 0) {
               my $dstatus = ($ref->{status} eq '<NIHIL>') ? 'UNKNOWN' : $ref->{status};
	  	        $tstatus = $dstatus;

                if ($dstatus eq 'OK' and $trendline) {
                  my $tSeconden = int(substr($ref->{duration}, 6, 2)) + int(substr($ref->{duration}, 3, 2)*60) + int(substr($ref->{duration}, 0, 2)*3600);
			      $tstatus = 'TRENDLINE' if ($tSeconden > $trendline);
	  		    }

                $itemStatus[$timeslot] = $tstatus;
                $itemStarttime[$timeslot] = $ref->{startTime};
                $itemTimeslot[$timeslot]  = $ref->{timeslot};
                ($ref->{statusMessage}, undef) = split(/\|/, $ref->{statusMessage}, 2); # remove performance data
                $ref->{filename} =~ s/^$RESULTSPATH\//$RESULTSURL\//g;

                my $tstatusMessage = ($ref->{filename} eq '<NIHIL>') ? encode_html_entities('M', $ref->{statusMessage}) : '<A HREF="'.$ref->{filename}.'" TARGET="_blank">'.encode_html_entities('M', $ref->{statusMessage}).'</A>';
                $statusIcon = ($acked and ($activationTimeslot - $step < $ref->{timeslot}) and ($suspentionTimeslot > $ref->{timeslot})) ? $ICONSACK {$tstatus} : $ICONS{$tstatus};
                $tempStatusMessage[$timeslot] = encode_html_entities('T', $ref->{title}).'</TD><TD VALIGN="TOP"><IMG SRC="'.$IMAGESURL.'/'.$statusIcon.'" WIDTH="16" HEIGHT="16" BORDER=0 title="'.$tstatus.'" alt="'.$tstatus.'"></TD><TD class="StatusMessage">'.$ref->{startTime}.'</TD><TD class="StatusMessage">'.$tstatusMessage if ($dstatus ne 'OK' and $dstatus ne 'OFFLINE' and $dstatus ne 'NO DATA' and $dstatus ne 'NO TEST');
                $emptyFullView = 0;
              }
            }

            $sth->finish() or $rv = errorTrapDBI($checklist, "Cannot sth->finish: $findString");
          }

          $playSoundPreviousStatus = $playSoundInProgress = 0;

          for ($number = 0; $number < $NUMBEROFFTESTS; $number++) {
            my $endTime = $itemStarttime[$number];
            $endTime .= "-" . $itemTimeslot[$number] if ($displayTimeslot);
            printItemStatus($tinterval, $number+1, $itemStatus[$number], $endTime, $acked, $itemTimeslot[$number], $activationTimeslot, $suspentionTimeslot, $persistent, $downtime, $suspentionTimeslotPersistentTrue, $suspentionTimeslotPersistentFalse, $uniqueKey);
          }

          for ($number = 0; $number < $NUMBEROFFTESTS; $number++) {
            if (defined $tempStatusMessage[$number]) {
              push (@itemStatusMessage, $tempStatusMessage[$number]);
              push (@printStatusMessage, $printCondensedView);
            }
          }
        }

        printItemFooter('');
      }

      print "\n" if ($debug);			
    }

    printGroepCV($prevGroep, 1, 0);

    if ($lockMySQL) {
      if ($dbh and $rv) {
        $unlockString = 'UNLOCK TABLES';
        $dbh->do ( $unlockString ) or $rv = errorTrapDBI($checklist, "Cannot dbh->do: $unlockString");
      }
    }

    $dbh->disconnect or $rv = errorTrapDBI($checklist, "Sorry, the database was unable to add your entry.") if ($dbh and $rv);
  }

  printGroepFooter('', 0);
  printStatusHeader('', $emptyFullView, $emptyCondencedView, $playSoundStatus);

  if (@itemStatusMessage) { 
    my $teller = 0;
    $emptyStatusMessage = 0;

    foreach $dstatusMessage (@itemStatusMessage) { 
      printStatusMessage($dstatusMessage, $printStatusMessage[$teller]);
      $teller++;
    }
  }

  printStatusFooter('', $emptyFullView, $emptyCondencedView, $emptyStatusMessage, $playSoundStatus);
  printHtmlFooter('');
  close(HTML);
  close(HTMLCV);
  rename("$htmlOutput.tmp", "$htmlOutput.html") if (-e "$htmlOutput.tmp");
  rename("$htmlOutput-cv.tmp", "$htmlOutput-cv.html") if (-e "$htmlOutput-cv.tmp");

  if ( $loop ) {
    my ($prevSecs, $currSecs);
    $currSecs = int((localtime)[0]);

    do {
      sleep 5;
      $prevSecs = $currSecs;
      $currSecs = int((localtime)[0]);
    } until ($currSecs < $prevSecs);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signal_DIE {
  #print "kill -DIE <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signal_WARN {
  #print "kill -WARN <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signalQUIT {
  print "kill -QUIT <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
  unlink $pidfile;
  $boolean_daemonQuit = 1;
  exit 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub signalHUP {
  print "kill -HUP <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";
  $boolean_signal_hup = 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub write_pid {
  print "write PID <$PROGNAME v$version -C $checklist> pid: <$pidfile><", get_datetimeSignal(), ">\n";

  if (-e "$pidfile") {
    print "ERROR: couldn't create pid file <$pidfile> for <$PROGNAME v$version -C $checklist>\n";
    exit 0;
  } else {
    open(PID,">$pidfile") || die "Cannot open $pidfile!!\n";
      print PID $$;
    close(PID);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_dir {
  my ($directory) = @_;

  unless ( -e "$directory" ) {                            # create $directory
    my ($status, $stdout, $stderr) = call_system ("mkdir $directory", 0);
    print "    create_dir ---- : mkdir $directory: $status, $stdout, $stderr\n" if ( ! $status or $stderr ne '' );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($checklist, $error_message) = @_;

  print $error_message, "\nERROR: $DBI::err ($DBI::errstr)\n";

  unless ( -e "$RESULTSPATH/$checklist-MySQL-sql-error.txt" ) {
    my $subject = "$prgtext / Current status for $checklist: " . get_datetimeSignal();
    my $message = get_datetimeSignal() . " $error_message\n--> ERROR: $DBI::err ($DBI::errstr)\n";
    my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, $subject, $message, $debug );
    print "Problem sending email to the '$APPLICATION' server administrators\n" unless ( $returnCode );
  }

  $rvOpen = open(DEBUG,">>$RESULTSPATH/$checklist-MySQL-sql-error.txt");

  if ($rvOpen) {
    print DEBUG get_datetimeSignal, ' ', $error_message, "\n--> ERROR: $DBI::err ($DBI::errstr)\n";
    close(DEBUG);
  } else {
    print "Cannot open $RESULTSPATH/$checklist-MySQL-sql-error.txt to print debug information\n";
  }

  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHtmlHeader {
  my $htmlTitle = shift(@_);

  print_header (*HTML, $pagedir, "$pageset-cv", $htmlTitle, "Full View", 60, "ONLOAD=\"startRefresh();\"", 'T', "", undef);
  print HTML '<TABLE WIDTH="100%">', "\n";

  print_header (*HTMLCV, $pagedir, "$pageset", $htmlTitle, "Condenced View", 60, "ONLOAD=\"startRefresh();\"", 'T', "", undef);
  print HTMLCV '<TABLE WIDTH="100%">', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printGroepHeader {
  my ($title, $show) = @_;

  if ($show) {
    $groupCondensedView = 0;
    delete @itemCondensedView[0..@itemCondensedView];
 	delete @printCondensedView[0..@printCondensedView];
    print HTML '<TR><TD class="GroupHeader" COLSPAN="', $colspanDisplayTime, '">', encode_html_entities('T', $title), '</TD></TR>', "\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printStatusHeader {
  my ($title, $emptyFullView, $emptyCondencedView, $playSoundStatus) = @_;

  my ($emptyFullViewMessage, $emptyCondencedViewMessage);

  if ($emptyFullView) {
    $emptyCondencedViewMessage = $emptyFullViewMessage = 'Contact ASAP the server administrators, probably database problems!!!';
  } elsif ($emptyCondencedView) {
    $emptyCondencedViewMessage = 'All Monitored Applications are OK';
  }
 
  if (defined $emptyFullViewMessage) {
    print HTML   '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '"><BR><H1>', $emptyFullViewMessage, '</H1></TD></TR>', "\n", '</TABLE>', "\n";
  } else {
    print HTML   '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '">', $STATUSHEADER01, '</TD></TR>', "\n", '</TABLE>', "\n";
  }

  print_legend (*HTML);
  print HTML   '<TABLE WIDTH="100%">', "\n";

  if (defined $emptyCondencedViewMessage) {
    print HTMLCV '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '"><BR><H1>', $emptyCondencedViewMessage, '</H1></TD></TR>', "\n", '</TABLE>', "\n";
  } else {
    print HTMLCV '<TR><TD class="StatusHeader" COLSPAN="', $colspanDisplayTime, '">', $STATUSHEADER01, '</TD></TR>', "\n", '</TABLE>', "\n";
  }

  print_legend (*HTMLCV);
  print HTMLCV '<TABLE WIDTH="100%">', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printItemHeader {
  my ($resultsdir, $uniqueKey, $command, $title, $help) = @_;

  my $htmlFilename = "$RESULTSPATH/$resultsdir/$command-$uniqueKey";
  $htmlFilename .= "-sql.html";

  unless ( -e "$htmlFilename" ) {
    my $rvOpen = open(PNG, ">$htmlFilename");

    if ($rvOpen) {
      print PNG <<EOM;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
  <title>$APPLICATION @ $BUSINESS</title>
  <META HTTP-EQUIV="Expires" CONTENT="Wed, 10 Dec 2003 00:00:01 GMT">
  <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
  <META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
  <META HTTP-EQUIV="Refresh" CONTENT="60">
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/asnmtap.css">
</HEAD>
<BODY>
EOM

      print PNG '<IMG SRC="', $RESULTSURL, '/', $resultsdir, '/', $command, '-', $uniqueKey, '-sql.png"></BODY></HTML>', "\n";
      close(PNG);
    } else {
      print "Cannot create $htmlFilename!\n";
    }
  }

  my ($posTokenFrom, $posTokenTo, $groep, $test);
  $posTokenFrom = index $title, '[';

  if ($posTokenFrom eq -1) {
    $groep = "";
    $test  = "$title"
  } else {
    $posTokenTo = index $title, "]", $posTokenFrom+1;
    $groep = substr($title, $posTokenFrom, $posTokenTo+2);
    $test  = substr($title, $posTokenTo+2);
  }

  my $comments = '<TD WIDTH="36"><A HREF="/cgi-bin/comments.pl?pagedir='.$pagedir.'&amp;pageset='.$pageset.'&amp;debug=F&amp;CGICOOKIE=1&amp;action=listView&amp;uKey='.$uniqueKey.'" target="_self"><IMG SRC="'.$IMAGESURL.'/'.$ICONSRECORD{maintenance}.'" WIDTH="15" HEIGHT="15" title="Comments" alt="Comments" BORDER=0></A> ';
  my $helpfile = (defined $help and $help eq '1') ? '<A HREF="/cgi-bin/getHelpPlugin.pl?pagedir='.$pagedir.'&amp;pageset='.$pageset.'&amp;debug=F&amp;CGICOOKIE=1&amp;uKey='.$uniqueKey.'" target="_self"><IMG SRC="'.$IMAGESURL.'/question.gif" WIDTH="15" HEIGHT="15" title="Help" alt="Help" BORDER=0></A></TD>' : '<IMG SRC="'.$IMAGESURL.'/spacer.gif" WIDTH="15" HEIGHT="15" title="" alt="" BORDER=0></TD>';
  print HTML '  <TR>', "\n",'    ', $comments, $helpfile, "\n", '    <TD class="ItemHeader">', $groep, '<A HREF="#" class="ItemHeaderTest" onclick="openPngImage(\'';

  $itemCondensedView = "";
  $checkOk = $checkSkip = $printCondensedView = $problemSolved = $verifyNumber = 0;
  $inProgressNumber = -1;

  $itemCondensedView .= '  <TR>'."\n".'    '.$comments.$helpfile."\n".'    <TD class="ItemHeader">'.$groep.'<A HREF="#" class="ItemHeaderTest" onclick="openPngImage(\'';
  print HTML $RESULTSURL, '/', $resultsdir, '/', $command, "-" , $uniqueKey, "-sql.html',910,550,null,null,'ChartDirector',10,false,'ChartDirector');\">", encode_html_entities('T', $test), '</A></TD>', "\n";
  $itemCondensedView .= $RESULTSURL .'/'. $resultsdir .'/'. $command . "-" . $uniqueKey . "-sql.html',910,550,null,null,'ChartDirector',10,false,'ChartDirector');\">" . encode_html_entities('T', $test) . '</A></TD>' . "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printGroepCV {
  my ($title, $showGroup, $showFooter) = @_;

  if ($showGroup and $title ne '') {
    if ($groupCondensedView) {
      print HTMLCV '<TR><TD class="GroupHeader" COLSPAN=', $colspanDisplayTime, '>', encode_html_entities('T', $title), '</TD></TR>', "\n";
      my $teller = 0;

      foreach $itemCondensedView (@itemCondensedView) {
        print HTMLCV $itemCondensedView[$teller] if ($printCondensedView[$teller]);
        $teller++;
      }

	  $emptyCondencedView = ($teller == 0) ? $emptyCondencedView : 0;
      print HTMLCV '<tr style="{height: 4;}"><TD></TD></TR>', "\n", if $showFooter;
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printItemStatus {
  my ($interval, $number, $status, $endTime, $acked, $timeslot, $activationTimeslot, $suspentionTimeslot, $persistent, $downtime, $suspentionTimeslotPersistentTrue, $suspentionTimeslotPersistentFalse, $uniqueKey) = @_;

  my $statusIcon = ($acked and ($activationTimeslot - $step < $timeslot) and ($suspentionTimeslot > $timeslot)) ? $ICONSACK {$status} : $ICONS{$status};

  my ($debugInfo, $boldStart, $boldEnd);
  $debugInfo = $boldStart = $boldEnd = '';

  if ($number == 0) {
    $printCondensedView = 1 unless ( $status eq 'IN PROGRESS' or $status eq 'OK' or $status eq 'NO TEST' or $status eq 'OFFLINE' );
    if ($ERRORS{$status} <= $ERRORS{UNKNOWN} or $ERRORS{$status} == $ERRORS{'NO DATA'}) { $playSoundStatus = ($playSoundStatus > $ERRORS{$status}) ? $playSoundStatus : $ERRORS{$status}; }
  } else {
    my $playSoundSet = 0;

    unless ( $printCondensedView or $problemSolved or $checkSkip == $inProgressNumber) {
      if ( $number == 1 ) {
        $verifyNumber = $VERIFYNUMBEROK;

	    if ( $interval < $VERIFYMINUTEOK ) {
          $verifyNumber = int($VERIFYMINUTEOK / $interval);

  	      if ( $verifyNumber > $NUMBEROFFTESTS ) {
            $verifyNumber = $NUMBEROFFTESTS;
          } elsif ($verifyNumber < $VERIFYNUMBEROK) {
            $verifyNumber = $VERIFYNUMBEROK;
	      }
        }

        $inProgressNumber = $verifyNumber;

        if ( $verifyNumber < $NUMBEROFFTESTS ) {
          $debugInfo .= "a-" if ($debug);
          $inProgressNumber++ if ( $status eq 'IN PROGRESS' );
  	    }

        if ( $status eq 'IN PROGRESS' ) {
          $playSoundInProgress = 1;
        } else {
          $playSoundPreviousStatus = $ERRORS{$status};
        }
      }

      my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);
      my $solvedDate     = "$currentYear-$currentMonth-$currentDay";
      my $solvedTime     = "$currentHour:$currentMin:$currentSec";
      my $solvedTimeslot = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);

      my $notDowntimeOrPersistent = 1;

      if ( $downtime or $persistent ) {
        $notDowntimeOrPersistent = ( $solvedTimeslot >= $activationTimeslot ) ? 0 : 1;
      }
	  
      if ( $number <= $inProgressNumber ) {
        $debugInfo .= "b-" if ($debug);
        $checkOk++ if ( $status eq 'OK' );

        if ( $notDowntimeOrPersistent and ($status eq 'IN PROGRESS' or $status eq 'OK' or $status eq 'NO TEST' or $status eq 'OFFLINE' ) ) {
          $checkSkip++ unless ( $acked and $status eq 'NO TEST' );
        } else {
          $printCondensedView = 1
        }
      } elsif ( $checkOk < $verifyNumber ) {
        $debugInfo .= "c-" if ($debug);
        $printCondensedView = ( $checkSkip == $inProgressNumber ) ? 0 : 1;
      }

      if ( $checkOk >= $verifyNumber ) {
        $debugInfo .= "s-" if ($debug);
        $problemSolved = 1;
      }

      $debugInfo .= "$downtime-$inProgressNumber-$verifyNumber-$checkOk-$checkSkip-$printCondensedView-$problemSolved-" if ($debug);

      my $update   = 0;
      my $sqlWhere = "";

      if ( $persistent == 0 ) {
        if ( $problemSolved ) {
          if ($solvedTimeslot > $activationTimeslot) {
  	        $sqlWhere = ' and persistent="0" and "' .$solvedTimeslot. '">activationTimeslot';
            $update = 1;
          }
        } elsif ($number == 1) {
          if ($activationTimeslot != 9999999999 and $suspentionTimeslotPersistentFalse != 0) {
            if ($suspentionTimeslotPersistentFalse < $solvedTimeslot) {
              $sqlWhere = ' and persistent="0" and "' .$solvedTimeslot. '">suspentionTimeslot';
              $update = 1;
            }
          }
        }
      } elsif ( $persistent == 1 ) {
        if ($number == 1) {
          if ($activationTimeslot != 9999999999 and $suspentionTimeslotPersistentTrue != 0) {
            if ($suspentionTimeslotPersistentTrue < $solvedTimeslot) {
              $sqlWhere = ' and persistent="1" and "' .$solvedTimeslot. '">suspentionTimeslot';
              $update = 1;
            }
          }
        }
      }

      if ($update) {
        my $sql = 'UPDATE ' .$SERVERTABLCOMMENTS. ' SET problemSolved="1", solvedDate="' .$solvedDate. '", solvedTime="' .$solvedTime. '", solvedTimeslot="' .$solvedTimeslot. '" where uKey="' .$uniqueKey. '" and problemSolved="0"' .$sqlWhere;
        $dbh->do ( $sql ) or $rv = errorTrapDBI($checklist, "Cannot dbh->do: $sql");
      }
    }

  	if ( $number == 2 ) {
      if ( $playSoundInProgress ) {
        $playSoundPreviousStatus = $ERRORS{$status};
      } else {
        $playSoundSet = 1;
      }
	} elsif ( $number == 3 and $playSoundInProgress ) {
      $playSoundSet = 1;
    }
	
    if ( $playSoundSet ) {
      $playSoundSet = 0;

      if ( ( $ERRORS{$status} == $ERRORS{OK} or ( $ERRORS{$status} >= $ERRORS{DEPENDENT} and $ERRORS{$status} != $ERRORS{'NO DATA'} and $ERRORS{$status} != $ERRORS{TRENDLINE} ) ) and ( ( $playSoundPreviousStatus >= $ERRORS{WARNING} and $playSoundPreviousStatus <= $ERRORS{UNKNOWN} ) or $playSoundPreviousStatus == $ERRORS{'NO DATA'} or $playSoundPreviousStatus == $ERRORS{TRENDLINE} ) ) {
        if ( defined $tableSoundStatusCache { $uniqueKey } ) {
          if ( $tableSoundStatusCache { $uniqueKey } ne $timeslot ) {
            $playSoundStatus = ($playSoundStatus > $playSoundPreviousStatus) ? $playSoundStatus : $playSoundPreviousStatus; 
            $tableSoundStatusCache { $uniqueKey } = $timeslot;
            $debugInfo .= "$playSoundStatus-" if ($debug);
            $boldStart = "<b>["; $boldEnd = "]</b>";
          } else {
            $debugInfo .= "C-" if ($debug);
          }
        } else {
          $playSoundStatus = ($playSoundStatus > $playSoundPreviousStatus) ? $playSoundStatus : $playSoundPreviousStatus;
          $tableSoundStatusCache { $uniqueKey } = $timeslot;
          $debugInfo .= "$playSoundStatus-" if ($debug);
          $boldStart = "<b>["; $boldEnd = "]</b>";
        }
      } else {
        delete $tableSoundStatusCache { $uniqueKey } if ( defined $tableSoundStatusCache { $uniqueKey } );
      }
    }

    if ($displayTime) {
      print HTML '    <TD><IMG SRC="', $IMAGESURL, '/', $statusIcon, '" WIDTH="16" HEIGHT="16" BORDER=0 title="', $status, '" alt="', $status, '"></TD>', "\n";
      print HTML '    <TD class="ItemStatus"><FONT COLOR="', $COLORS{$status}, '">', $debugInfo, $boldStart, $endTime, $boldEnd, '</FONT></TD>', "\n";
    } else {
      print HTML '    <TD><IMG SRC="', $IMAGESURL, '/', $statusIcon, '" WIDTH="16" HEIGHT="16" BORDER=0 title="', $endTime, '" alt="', $endTime, '"></TD>', "\n";
    }
  }

  if ($displayTime) {
    $itemCondensedView .= '    <TD><IMG SRC="'. $IMAGESURL .'/'. $statusIcon .'" WIDTH="16" HEIGHT="16" BORDER=0 title="'. $status .'" alt="'. $status .'"></TD>'. "\n";
    $itemCondensedView .= '    <TD class="ItemStatus"><FONT COLOR="'. $COLORS{$status} .'">'. $debugInfo . $boldStart . $endTime . $boldEnd .'</FONT></TD>'. "\n";
  } else {
    $itemCondensedView .= '    <TD><IMG SRC="'. $IMAGESURL .'/'. $statusIcon .'" WIDTH="16" HEIGHT="16" BORDER=0 title="'. $endTime .'" alt="'. $endTime .'"></TD>'. "\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printStatusMessage {
  my ($statusMessage, $printStatusMessage) = @_;

  my $break = '';
  my $errorMessage;

  # ***************************************************************************
  # The 400 series of Web error codes indicate an error with your Web browser *
  # ***************************************************************************
  if ($statusMessage =~ /400 Bad Request/ ) {
    $errorMessage = 'The request could not be understood by the server due to incorrect syntax';
  } elsif ($statusMessage =~ /401 Unauthorized User/ ) {
    $errorMessage = 'The client does not have access to this resource, authorization is needed';
  } elsif ($statusMessage =~ /402 Payment Required/ ) {
    $errorMessage = 'Payment is required. Reserved for future use';
  } elsif ($statusMessage =~ /403 Forbidden Connection/ ) {
    $errorMessage = 'The server understood the request, but is refusing to fulfill it. Access to a resource is not allowed. The most frequent case of this occurs when directory listing access is not allowed';
  } elsif ($statusMessage =~ /404 Page Not Found/ ) {
    $errorMessage = 'The resource request was not found. This is the code returned for missing pages or graphics. Viruses will often attempt to access resources that do not exist, so the error does not necessarily represent a problem';
  } elsif ($statusMessage =~ /405 Method Not Allowed/ ) {
    $errorMessage = 'The access method (GET, POST, HEAD) is not allowed on this resource';
  } elsif ($statusMessage =~ /406 Not Acceptable/ ) {
    $errorMessage = 'None of the acceptable file types (as requested by client) are available for this resource';
  } elsif ($statusMessage =~ /407 Proxy Authentication Required/ ) {
    $errorMessage = 'The client does not have access to this resource, proxy authorization is needed';
  } elsif ($statusMessage =~ /408 Request Timeout/ ) {
    $errorMessage = 'The client did not send a request within the required time period';
  } elsif ($statusMessage =~ /409 Conflict/ ) {
    $errorMessage = 'The request could not be completed due to a conflict with the current state of the resource';
  } elsif ($statusMessage =~ /410 Gone/ ) {
    $errorMessage = 'The requested resource is no longer available at the server and no forwarding address is known. This condition is similar to 404, except that the 410 error condition is expected to be permanent. Any robot seeing this response should delete the reference from its information store';
  } elsif ($statusMessage =~ /411 Length Required/ ) {
    $errorMessage = 'The request requires the Content-Length HTTP request field to be specified';
  } elsif ($statusMessage =~ /412 Precondition Failed/ ) {
    $errorMessage = 'The precondition given in one or more of the request-header fields evaluated to false when it was tested on the server';
  } elsif ($statusMessage =~ /413 Request Entity Too Large/ ) {
    $errorMessage = 'The server is refusing to process a request because the request entity is larger than the server is willing or able to process';
  } elsif ($statusMessage =~ /414 Request URL Too Large/ ) {
    $errorMessage = 'The server is refusing to service the request because the Request-URI is longer than the server is willing to interpret The URL is too long (possibly too many query keyword/value pairs)';
  } elsif ($statusMessage =~ /415 Unsupported Media Type/ ) {
    $errorMessage = 'The server is refusing to service the request because the entity of the request is in a format not supported by the requested resource for the requested method';
  } elsif ($statusMessage =~ /416 Requested Range Invalid/ ) {
    $errorMessage = 'The portion of the resource requested is not available or out of range';
  } elsif ($statusMessage =~ /417 Expectation Failed/ ) {
    $errorMessage = 'The Expect specifier in the HTTP request header can not be met';
  # ***************************************************************************
  # The 500 series of Web error codes indicate an error with the Web server   *
  # ***************************************************************************
  } elsif ($statusMessage =~ /500 Can't connect to proxy/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /500 Connect failed/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /500 Internal Server Error/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message (client certificate maybe needed)';
  } elsif ($statusMessage =~ /500 Proxy connect failed/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /500 Server Error/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /500 SSL read timeout/ ) {
    $errorMessage = 'The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message';
  } elsif ($statusMessage =~ /501 Not Implemented/ ) {
    $errorMessage = 'Function not implemented in Web server software. The request needs functionality not available on the server';
  } elsif ($statusMessage =~ /502 Bad Gateway/ ) {
    $errorMessage = 'Bad Gateway: a server being used by this Web server has sent an invalid response. The response by an intermediary server was invalid. This may happen if there is a problem with the DNS routing tables';
  } elsif ($statusMessage =~ /503 Service Unavailable/ ) {
    $errorMessage = 'Service temporarily unavailable because of currently/temporary overload or maintenance';
  } elsif ($statusMessage =~ /504 Gateway Timeout/ ) {
    $errorMessage = 'The server did not respond back to the gateway within acceptable time period';
  } elsif ($statusMessage =~ /505 HTTP Version Not Supported/ ) {
    $errorMessage = 'The server does not support the HTTP protocol version that was used in the request message';
  # ***************************************************************************
  # Error codes indicate an error with the ...                                *
  # ***************************************************************************
  } elsif ($statusMessage =~ /Failure of server APACHE bridge/ ) {
    $errorMessage = 'Weblogic Bridge Message: Failure of server APACHE bridge';

    if ($statusMessage =~ /No backend server available for connection/ ) {
      $errorMessage .= ' - No backend server available for connection';
    } elsif ($statusMessage =~ /Cannot connect to the server/ ) {
      $errorMessage .= ' - Cannot connect to the server';
    } elsif ($statusMessage =~ /Cannot connect to WebLogic/ ) {
      $errorMessage .= ' - Cannot connect to WebLogic';
    }
  # ***************************************************************************
  # Error codes indicate an error with Cactus XML::Parser                     *
  # ***************************************************************************
  } elsif ($statusMessage =~ /Cactus XML::Parser:/ ) {
    $statusMessage =~ s/\+{2}/\+\+<br>/g;
  } elsif (-s "$PREFIXPATH/applications/custom/display.pm") {
    require "$PREFIXPATH/applications/custom/display.pm";
	$errorMessage = printStatusMessageCustom( decode_html_entities('E', $statusMessage) );
  }

  print HTML '  <TR><TD class="StatusItem">', $statusMessage, '</TD></TR>', "\n";
  if ($errorMessage) { print HTML '  <TR><TD COLSPAN="3"></TD><TD class="StatusMessageError">', encode_html_entities('E', $errorMessage), '</TD></TR>', "\n"; }

  if ($printStatusMessage) {
    print HTMLCV '  <TR><TD class="StatusItem">', $statusMessage, '</TD></TR>', "\n";
    if ($errorMessage) { print HTMLCV '  <TR><TD COLSPAN="3"></TD><TD class="StatusMessageError">', encode_html_entities('E', $errorMessage), '</TD></TR>', "\n"; }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHtmlFooter {
  my $title = @_;

  print HTML   "</BODY>\n</HTML>";
  print HTMLCV "</BODY>\n</HTML>";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printGroepFooter {
  my ($title, $show) = @_;

  print HTML '<TR style="{height: 4;}"><TD></TD></TR>', "\n" if ($show);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printItemFooter {
  my ($title) = @_;

  print HTML '</TR>', "\n";
  $itemCondensedView .= '</TR>' . "\n";
  $groupCondensedView += $printCondensedView;
  push (@itemCondensedView, $itemCondensedView);
  push (@printCondensedView, $printCondensedView);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printStatusFooter {
  my ($title, $emptyFullView, $emptyCondencedView, $emptyStatusMessage, $playSoundStatus) = @_;

  print HTML   '</TABLE>', "\n";
  print HTML   '<HR>', "\n" unless ( $emptyFullView or $emptyStatusMessage );
  print HTML   "<embed src=\"$HTTPSURL/sound/", $SOUND{$playSoundStatus}, "\" alt=\"\"  hidden=\"true\" autostart=\"true\">\n" if ($playSoundStatus);

  print HTMLCV '</TABLE>', "\n";
  print HTMLCV '<HR>', "\n" unless ( $emptyFullView or $emptyCondencedView or $emptyStatusMessage );
  print HTMLCV "<embed src=\"$HTTPSURL/sound/", $SOUND{$playSoundStatus}, "\" alt=\"\" hidden=\"true\" autostart=\"true\">\n" if ($playSoundStatus);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME -H <MySQL hostname> [-C <Checklist>] [-P <pagedir>] [-L <loop>] [-T <displayTime>] [-l <lockMySQL>] [-D <debug>] [-V version] [-h help]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision($PROGNAME, $version);
  print "ASNMTAP Display for the '$APPLICATION'

-H, --hostname=<HOSTNAME>
   HOSTNAME : hostname/address from the MySQL server
-C, --checklist=<FILENAME>
   FILENAME : filename from the checklist for the html output loop (default 'DisplayCT')
-P, --pagedir=<PAGEDIR>
   PAGEDIR  : sub directory name for the html output (default 'index')
-L, --loop=F|T
   F(alse)  : loop off (default)
   T(rue)   : loop on
-T, --displayTime=F|T
   F(alse)  : display timeslots into html output off
   T(rue)   : display timeslots into html output (default)
-l, --lockMySQL=F|T
   F(alse)  : lock MySQL table off (default)
   T(rue)   : lock MySQL table on
-D, --debug=F|T
   F(alse)  : screendebugging off (default)
   T(true)  : normal screendebugging on
-V, --version
-h, --help

Send email to $SENDEMAILTO if you have questions regarding
use of this software. To submit patches or suggest improvements, send
email to $SENDEMAILTO

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
