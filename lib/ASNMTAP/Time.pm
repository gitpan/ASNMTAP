# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/29, v3.000.002, package ASNMTAP::Time
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Time;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Time::ISA         = qw(Exporter);

  %ASNMTAP::Time::EXPORT_TAGS = (ALL       => [ qw(&get_timeslot
                                                   &get_yearMonthDay
                                                   &get_yyyymmddhhmmsswday
                                                   &get_datetimeSignal &get_datetime
                                                   &get_hour &get_min &get_seconds
                                                   &get_logfiledate &get_csvfiledate &get_csvfiletime
                                                   &get_epoch &get_week &get_wday &get_day &get_month &get_year) ],

                                 DATE      => [ qw(&get_epoch &get_week &get_wday &get_day &get_month &get_year) ],

                                 LOCALTIME => [ qw(&get_timeslot
                                                   &get_yearMonthDay
                                                   &get_yyyymmddhhmmsswday
                                                   &get_datetimeSignal &get_datetime
                                                   &get_hour &get_min &get_seconds
                                                   &get_logfiledate &get_csvfiledate &get_csvfiletime) ] );

  @ASNMTAP::Time::EXPORT_OK   = ( @{ $ASNMTAP::Time::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Time::VERSION     = 3.000.002;
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Private subs  = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _checkReadOnly0 { if ( @_ > 0 ) { cluck "Syntax error: Can't change value of read-only function ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
sub _checkReadOnly1 { if ( @_ > 1 ) { cluck "Syntax error: Can't change value of read-only function ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Epochtime:
#
# To get the current time, Perl has a built-in function called time().
# This simply returns the number of non-leap seconds that have elapsed 
# since 00:00:00 January 1, 1970 UTC.
#
# current epochtime equal to time()
#
# timelocal((localtime)[0,1,2,3,4,5]) = timelocal(localtime)

# List Element Description:
#
# localtime() converts the UTC time into the correct values for the local time zone. 
#
# localtime() uses the current time -> localtime(time()) equal to localtime(time)
#
# (localtime)[0]: sec Seconds after each minute (0 - 59)
# (localtime)[1]: min Minutes after each hour (0 - 59)
# (localtime)[2]: hour Hour since midnight (0 - 23)
# (localtime)[3]: monthday Numeric day of the month (1 - 31)
# (localtime)[4]: month Number of months since January (0 - 11)
# (localtime)[5]: year Number of years since 1900
# (localtime)[6]: weekday Number of days since Sunday (0 - 6)
# (localtime)[7]: yearday Number of days since January 1 (0 - 365)
# (localtime)[8]: isdaylight A flag for daylight savings time
#
# ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime( time() );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_timeslot {
  &_checkReadOnly1;

  my $timeslot;

  if (defined $_[0]) {
    $timeslot = timelocal ( 0, (localtime($_[0]))[1,2,3,4,5] );
  } else {
    $timeslot = timelocal ( 0, (localtime)[1,2,3,4,5] );
  }

  return ( $timeslot );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_yearMonthDay {
  &_checkReadOnly1;

  if (defined $_[0]) {
    return (sprintf ("%04d%02d%02d", (localtime($_[0]))[5]+1900, (localtime($_[0]))[4]+1, (localtime($_[0]))[3]));
  } else {
    return (sprintf ("%04d%02d%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3]));
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_yyyymmddhhmmsswday { &_checkReadOnly0; return sprintf ("%04d:%02d:%02d:%02d:%02d:%02d:%d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3,2,1,0,6]); }

sub get_datetimeSignal     { &_checkReadOnly0; return sprintf ("%04d/%02d/%02d %02d:%02d:%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3,2,1,0]); }
sub get_datetime           { &_checkReadOnly0; return sprintf ("%02d%02d%02d%02d%02d%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3,2,1,0]); }

sub get_hour               { &_checkReadOnly0; return sprintf ("%02d", (localtime)[2]); }
sub get_min                { &_checkReadOnly0; return sprintf ("%02d", (localtime)[1]); }
sub get_seconds            { &_checkReadOnly0; return sprintf ("%02d", (localtime)[0]); }

sub get_logfiledate        { &_checkReadOnly0; return sprintf ("%04d%02d%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3]); }
sub get_csvfiledate        { &_checkReadOnly0; return sprintf ("%04d/%02d/%02d", (localtime)[5]+1900, (localtime)[4]+1, (localtime)[3]); }
sub get_csvfiletime        { &_checkReadOnly0; return sprintf ("%02d:%02d:%02d", (localtime)[2,1,0]); }

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub get_epoch {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly1;

  my $time = `date --date '$_[0]' '+%s'`;
  return ( undef ) unless ( $time );
  chomp ( $time );
  return ( $time );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_week {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly1;

  my $time = `date --date '$_[0]' '+%V'`;
  return ( undef ) unless ( $time );
  chomp ( $time );
  return ( $time );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_wday {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly1;

  my $time = `date --date '$_[0]' '+%w'`;
  return ( undef ) unless ( $time );
  chomp ( $time );
  return ( $time );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_day {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly1;

  my $time = `date --date '$_[0]' '+%d'`;
  return ( undef ) unless ( $time );
  chomp ( $time );
  return ( $time );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_month {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly1;

  my $time = `date --date '$_[0]' '+%m'`;
  return ( undef ) unless ( $time );
  chomp ( $time );
  return ( $time );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_year {
  return ( undef ) unless ( defined $_[0] ); &_checkReadOnly1;

  my $time = `date --date '$_[0]' '+%G'`;
  return ( undef ) unless ( $time );
  chomp ( $time );
  return ( $time );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Time is a Perl module that provides date and time functions used by ASNMTAP and ASNMTAP-based applications and plugins.

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.com]

Purpose: CronTab (CT, sysdCT),
         Disk Filesystem monitoring (DF, sysdDF),
         Intrusion Detection for FW-1 (ID, sysdID)
         Process System daemons (PS, sysdPS),
         Reachability of Remote Hosts on a network (RH, sysdRH),
         Rotate Logfiles (system activity files) (RL),
         Remote Socket monitoring (RS, sysdRS),
         System Activity monitoring (SA, sysdSA).

'Process System daemons' is based on 'sysdaemon 1.60' written by Trans-Euro I.T Ltd

=head1 LICENSE

ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut