#!/usr/bin/perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2006/09/16, v3.000.011, holidayBundleSetDowntimes.pl for ASNMTAP::Applications
# ---------------------------------------------------------------------------------------------------------
 
use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Date::Calc qw(Add_Delta_Days Day_of_Week Easter_Sunday Delta_Days);
use Time::Local;
use Getopt::Long;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications v3.000.011;
use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS

                                      $RMDEFAULTUSER
                                      $SMTPUNIXSYSTEM $SERVERLISTSMTP $SERVERSMTP $SENDMAILFROM
                                      &init_email_report &send_email_report 
                                      &error_Trap_DBI

                                      $DATABASE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                      $SERVERTABLCOMMENTS $SERVERTABLHLDSBNDL $SERVERTABLHOLIDYS $SERVERTABLPLUGINS $SERVERTABLUSERS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_V $opt_h $opt_D $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "holidayBundleSetDowntimes.pl";
my $prgtext     = "Set Holiday Bundle Downtimes for the '$APPLICATION'";
my $version     = '3.000.011';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $debug       = 0;                                            # default
my $daysBefore  = 3;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');

GetOptions (
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

my ($emailReport, $rvOpen) = init_email_report (*EMAILREPORT, "generateReports.txt", $debug);

# Init parameters
my ($rv, $dbh, $sth, $sql);

# open connection to database and query data
$rv  = 1;

$dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot connect to the database", $debug);

if ($dbh and $rv) {
  my ($holidayBundleID, $holidayBundleName, $holidayID);
  $sql = "select holidayBundleID, holidayBundleName, holidayID from $SERVERTABLHLDSBNDL where activated = '1' order by holidayBundleName";
  $sth = $dbh->prepare( $sql ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot dbh->prepare: $sql", $debug);
  $sth->execute() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug) if $rv;
  $sth->bind_columns( \$holidayBundleID, \$holidayBundleName, \$holidayID ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->bind_columns: $sql", $debug) if $rv;

  if ( $rv ) {
    if ( $sth->rows ) {
      my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);

      my ($daysBeforeYear, $daysBeforeMonth, $daysBeforeDay) = Add_Delta_Days ($currentYear, $currentMonth, $currentDay, $daysBefore);
      print "Current date: $currentYear/$currentMonth/$currentDay, Days before: $daysBefore, $daysBeforeYear/$daysBeforeMonth/$daysBeforeDay\n" if ($debug);

      my $entryDate     = "$currentYear-$currentMonth-$currentDay";
      my $entryTime     = "$currentHour:$currentMin:$currentSec";
      my $entryTimeslot = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);

      while( $sth->fetch() ) {
        print "--> $holidayBundleID, $holidayBundleName, $holidayID\n" if ($debug);

        if ($holidayID ne '') {
          chop $holidayID;
          my (undef, @holidayID) = split (/\//, $holidayID);

          foreach my $holidayID (@holidayID) {
            my $holidayYear;
            my ($holidayFormule, $holidayMonth, $holidayDay, $holidayOffset, undef) = split (/-/, $holidayID);
            print "    $holidayID, $holidayFormule, $holidayMonth, $holidayDay, $holidayOffset" if ($debug >= 2);

            if ($holidayFormule == 0) {
              $holidayYear = ($currentMonth == 12 and $currentDay > (31 - $daysBefore) and $holidayMonth == 1 and $holidayDay <= $daysBeforeDay) ? $daysBeforeYear : $currentYear;
              print ", Fixed day: $holidayMonth/$holidayDay, " if ($debug >= 2);
            } elsif ($holidayFormule == 1) {
              print ", Easter offset: $holidayOffset, " if ($debug >= 2);
              ($holidayYear, $holidayMonth, $holidayDay) = Add_Delta_Days(Easter_Sunday($daysBeforeYear), $holidayOffset);
            } else {
              if ($debug) {
                print ", ERROR: wrong formule\n";
              } else {
                print EMAILREPORT "$holidayBundleID, $holidayBundleName, $holidayID, ERROR: wrong formule\n";
              }
            }

            if (defined $holidayYear) {
              my $alert;
              my $holidayDayOfWeek = Day_of_Week ($holidayYear, $holidayMonth, $holidayDay);

              if ($holidayDayOfWeek >= 6) {       # zaterdag of zondag
                print "6-7: $holidayDayOfWeek, " if ($debug >= 2);
              } else {
                print "1-5: $holidayDayOfWeek, " if ($debug >= 2);
                my $deltaDays = Delta_Days ($holidayYear, $holidayMonth, $holidayDay, $daysBeforeYear, $daysBeforeMonth, $daysBeforeDay);
                print "Delta Days: $deltaDays, " if ($debug >= 2);

                if ($deltaDays >= 0 and $deltaDays <= $daysBefore) {
                  my ($holiday, $uKey, $title, $pagedirs, $commentData, $activationTimeslot, $suspentionTimeslot);

                  my $sql = "select holiday from $SERVERTABLHOLIDYS where holidayID = '$holidayID'";
                  my $sth = $dbh->prepare( $sql ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot dbh->prepare: $sql", $debug);
                  $sth->execute() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug) if $rv;

                  if ( $rv ) {
                    ($holiday) = $sth->fetchrow_array() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug) if $rv;
                    $sth->finish() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug);
                  }

                  $sql = "select uKey, title, pagedir from $SERVERTABLPLUGINS where holidayBundleID = '$holidayBundleID' and activated = '1' order by uKey";
                  $sth = $dbh->prepare( $sql ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot dbh->prepare: $sql", $debug);
                  $sth->execute() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug) if $rv;
                  $sth->bind_columns( \$uKey, \$title, \$pagedirs ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->bind_columns: $sql", $debug) if $rv;

                  if ( $rv ) {
                    if ( $sth->rows ) {
                      while( $sth->fetch() ) {
                        $alert .= "  > '$uKey'" if ($debug);
                        $activationTimeslot = timelocal(0, 0, 0, $holidayDay, $holidayMonth-1, $holidayYear-1900);
                        $suspentionTimeslot = timelocal(59, 59, 23, $holidayDay, $holidayMonth-1, $holidayYear-1900);
                        $alert .= " Holiday: $holidayYear/$holidayMonth/$holidayDay, From: $activationTimeslot (" .scalar(localtime($activationTimeslot)). "), To: $suspentionTimeslot (" .scalar(localtime($suspentionTimeslot)). ")" if ($debug);
                        my $sql = 'SELECT count(*) from ' .$SERVERTABLCOMMENTS. ' where uKey="' .$uKey. '" and downtime="1" and problemSolved="0" and activationTimeslot="' .$activationTimeslot. '" and suspentionTimeslot="' .$suspentionTimeslot. '"';
                        $alert .= "\n  C $sql" if ($debug >= 2);
                        my $sth = $dbh->prepare( $sql ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot dbh->prepare: $sql", $debug);
                        $sth->execute() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->execute: $sql", $debug) if $rv;
                        my $numberRecordExist = ($rv) ? $sth->fetchrow_array() : 0;
                        $sth->finish() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->finish: $sql", $debug) if $rv;

                        if ($numberRecordExist) {
                          $alert .= "\n  C - Downtime scheduled: # exist '$numberRecordExist'" if ($debug);
                        } else {
                          $alert .= "\n  P $pagedirs" if ($debug);
                          $commentData = "'$holiday' downtime scheduling for '$title' from $holidayYear-$holidayMonth-$holidayDay 00:00:00 until $holidayYear-$holidayMonth-$holidayDay 23:59:59";
                          $alert .= "\n  C + $commentData" if ($debug);
                          my $sql = 'INSERT INTO ' .$SERVERTABLCOMMENTS. ' SET uKey="' .$uKey. '", title="' .$title. '", entryDate="' .$entryDate. '", entryTime="' .$entryTime.'", entryTimeslot="' .$entryTimeslot. '", persistent="0", downtime="1", problemSolved="0", solvedDate="", solvedTime="", solvedTimeslot="", remoteUser="' .$RMDEFAULTUSER. '", commentData="' .$commentData. '", activationDate="' .$holidayYear. '-' .$holidayMonth. '-' .$holidayDay. '", activationTime="00:00:00", activationTimeslot="' .$activationTimeslot. '", suspentionDate="' .$holidayYear. '-' .$holidayMonth. '-' .$holidayDay. '", suspentionTime="23:59:59", suspentionTimeslot="' .$suspentionTimeslot. '"';
                          $alert .= "\n  C $sql" if ($debug >= 2);
                          $dbh->do ( $sql ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->do: $sql", $debug);

                          my ($sendEmailTo, $TremoteUser, $Temail, $Tpagedir);
                          $sql = "select remoteUser, email, pagedir from $SERVERTABLUSERS where activated = 1 and userType > 0";
                          $alert .= "\n  E $sql" if ($debug >= 2);
                          $sth = $dbh->prepare( $sql ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->finish: $sql", $debug);
                          $sth->execute() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->finish: $sql", $debug) if $rv;
                          $sth->bind_columns( \$TremoteUser, \$Temail, \$Tpagedir ) or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->finish: $sql", $debug) if $rv;

                          if ( $rv ) {
                            while( $sth->fetch() ) {
                              $alert .= "\n  E - $TremoteUser, $Temail, $Tpagedir" if ($debug >= 2);

                              chop $Tpagedir;
                              my (undef, @pagedirs) = split (/\//, $Tpagedir);

                              foreach my $Tpagedirs (@pagedirs) {
                                if ($pagedirs =~ /\/$Tpagedirs\//) {
                                  $alert .= "\n  E + send email to: $TremoteUser, $Temail for $Tpagedirs" if ($debug);
                                  $sendEmailTo .= "$Temail,";
                                  last;
                                }
                              }
                            }

                            $sth->finish() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->finish: $sql", $debug);

                            if (defined $sendEmailTo) {
                              $alert .= "\n  E = $sendEmailTo" if ($debug >= 2);
                              my $header = $commentData;
                              my $subject = "$BUSINESS / $DEPARTMENT / $APPLICATION / $header";
                              my $message = "Geachte, Cher,\n\n$header\n\n-- Administrator\n\n$APPLICATION\n$DEPARTMENT\n$BUSINESS\n";
                              my $returnCode = sending_mail ( $SERVERLISTSMTP, $sendEmailTo, $SENDMAILFROM, $subject, $message, $debug );
                              print "Problem sending email to the '$APPLICATION' members\n" unless ( $returnCode );
                            }
                          }
                        }

                        $alert .= "\n" if ($debug);
                      }
                    }

                    $sth->finish() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->finish: $sql", $debug);
                  }

                }
              }

              print "holiday: $holidayYear/$holidayMonth/$holidayDay\n" if ($debug >= 2);
              print " -> $holidayBundleID, $holidayBundleName, $holidayYear/$holidayMonth/$holidayDay\n$alert" if (defined $alert and $debug);
            }
          }
        }
      }
    }

    $sth->finish() or $rv = error_Trap_DBI(*EMAILREPORT, "Cannot sth->finish: $sql", $debug);
  }

  $dbh->disconnect or $rv = error_Trap_DBI(*EMAILREPORT, "Sorry, the database was unable to add your entry.", $debug);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($rc) = send_email_report (*EMAILREPORT, $emailReport, $rvOpen, $prgtext, $debug);
exit;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME [-D <debug>] [-V version] [-h help]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision($PROGNAME, $version);
  print "ASNMTAP Archiver for the '$APPLICATION'

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

