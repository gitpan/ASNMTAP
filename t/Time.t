# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 32;

BEGIN { require_ok ( 'ASNMTAP::Time' ) };

BEGIN { use_ok ( 'ASNMTAP::Time v3.000.003' ) };
BEGIN { use_ok ( 'ASNMTAP::Time' ) };
BEGIN { use_ok ( 'ASNMTAP::Time', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Time', qw(:DATE) ) };
BEGIN { use_ok ( 'ASNMTAP::Time', qw(:LOCALTIME) ) };
BEGIN { use_ok ( 'ASNMTAP::Time', qw(&get_timeslot &get_yearMonthDay &get_yyyymmddhhmmsswday &get_datetimeSignal &get_datetime &get_hour &get_min &get_seconds &get_logfiledate &get_csvfiledate &get_csvfiletime &get_epoch &get_week &get_wday &get_day &get_month &get_year) ) };

TODO: {
  ok ( get_timeslot(), 'ASNMTAP::Time::get_timeslot()' );

  ok ( get_yyyymmddhhmmsswday(), 'ASNMTAP::Time::get_yyyymmddhhmmsswday()' );
  ok ( get_datetimeSignal(), 'ASNMTAP::Time::get_datetimeSignal()' );
  ok ( get_datetime(), 'ASNMTAP::Time::get_datetime()' );

  ok ( get_hour(), 'ASNMTAP::Time::get_hour()' );
  ok ( get_min(), 'ASNMTAP::Time::get_min()' );
  ok ( get_seconds(), 'ASNMTAP::Time::get_seconds()' );

  ok ( get_epoch('now'), 'ASNMTAP::Time::get_epoch(\'now\')' );
  ok ( get_week('now'), 'ASNMTAP::Time::get_week(\'now\')' );

  ok ( get_csvfiletime(), 'ASNMTAP::Time::get_csvfiletime()' );

  use Time::Local;
  my $time = time();
  my $timeslot = timelocal ( 0, (localtime($time))[1,2,3,4,5] );
  my ($year, $month, $day, $wday) = ((localtime($time))[5]+1900, (localtime($time))[4]+1, (localtime($time))[3,6]);
  $year  = sprintf ("%04d", $year);
  $month = sprintf ("%02d", $month);
  $day   = sprintf ("%02d", $day);

  is ( get_wday('now'), $wday, 'ASNMTAP::Time::get_wday(\'now\')' );
  is ( get_day('now'), $day, 'ASNMTAP::Time::get_day(\'now\')' );
  is ( get_month('now'), $month, 'ASNMTAP::Time::get_month(\'now\')' );
  is ( get_year('now'), $year, 'ASNMTAP::Time::get_year(\'now\')' );

  is ( get_yearMonthDay(), "$year$month$day", 'ASNMTAP::Time::get_yearMonthDay()' );
  is ( get_logfiledate(), "$year$month$day", 'ASNMTAP::Time::get_logfiledate()' );
  is ( get_csvfiledate(), "$year/$month/$day", 'ASNMTAP::Time::get_csvfiledate()' );
  
  is ( get_yearMonthDay( $time ), "$year$month$day", 'ASNMTAP::Time::get_yearMonthDay( time() )' );

  is ( get_timeslot( $time ), $timeslot, 'ASNMTAP::Time::get_timeslot( time() )' );

  is ( get_epoch(),undef, 'ASNMTAP::Time::get_epoch()' );
  is ( get_week(), undef, 'ASNMTAP::Time::get_week()' );
  is ( get_wday(), undef, 'ASNMTAP::Time::get_wday()' );
  is ( get_day(), undef, 'ASNMTAP::Time::get_day()' );
  is ( get_month(), undef, 'ASNMTAP::Time::get_month()' );
  is ( get_year(), undef, 'ASNMTAP::Time::get_year()' );
}
