#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/01, v3.0, making ASNMTAP v3.xxx.xxx compatible
# ----------------------------------------------------------------------------------------------------------
# COPYRIGHT NOTICE
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be].                            All Rights Reserved.
#
# Asnmtap may be used and modified free of charge by anyone so long as this copyright notice and the comments
# above remain intact.  By using this code you agree to indemnify Alex Peeters from any liability that might 
# arise from it's use.
#
# Selling the code for this program without prior written consent is expressly forbidden.    In other words, 
# please ask first before you try and make money off of my program.
#
# Obtain permission before redistributing this software over the Internet or in any other medium.
# In all cases copyright and header must remain intact.
# ----------------------------------------------------------------------------------------------------------
# A monitor to determine if a MySQL database server is operational
#
# To ensure that your SQL server is responding on the proper port, this 
# attempts to connect and test the database on a given database server.
#
# This monitor requires the perl5 DBI, and DBD::mysql modules, available from CPAN
# ----------------------------------------------------------------------------------------------------------
#   mysql> GRANT SELECT SHOW DATABASE ON checklist.* TO asnmtap@hostname;
# or when -C T
#   mysql> GRANT SELECT SHOW DATABASE, REPLICATION SLAVE, REPLICATION CLIENT, SUPER ON checklist.* TO asnmtap@hostname-server;
# ----------------------------------------------------------------------------------------------------------
# For warning and critical calculations we need 'Bit-Vector-6.3' from 'http://search.cpan.org/dist/Bit-Vector/'
#   perl Makefile.PL
#   make
#   make test
#   make install
#
# For warning and critical calculations we need 'Date-Calc-5.3' from 'http://search.cpan.org/dist/Date-Calc/'
#   perl Makefile.PL
#   make
#   make test
#   make install
# ----------------------------------------------------------------------------------------------------------

use strict;

use Getopt::Long;
use strict;
use warnings;

use lib qw(/opt/asnmtap/.);
use ASNMTAP::Asnmtap::Plugins v3.000.003;
use ASNMTAP::Asnmtap::Plugins qw(:DEFAULT :ASNMTAP :PLUGINS);

use Getopt::Long;
use vars qw($opt_u $opt_p $opt_B $opt_b $opt_T $opt_P $opt_C $opt_H $opt_w $opt_c  $opt_t $opt_S $opt_D $opt_L $opt_d $opt_O $opt_A $opt_V $opt_h $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME    = "check_MySQL-database.pl";
my $version  = "3.0";
my $prgtext  = "MySQL database";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Date::Calc qw(Delta_DHMS);

my $username = 'replication';
my $password = 'replication';
my $database = 'asnmtap';
my $binlog   = 'asnmtap';
my $table    = 'events';
my $port     = '3306';
my $cluster  = 'F';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp ();
sub printUsage ();

Getopt::Long::Configure('bundling');

GetOptions (
  "u:s" => \$opt_u, "username:s"   => \$opt_u,
  "p:s" => \$opt_p, "password:s"   => \$opt_p,
  "B:s" => \$opt_B, "database:s"   => \$opt_B,
  "b:s" => \$opt_b, "binlog:s"     => \$opt_b,
  "T:s" => \$opt_T, "table:s"      => \$opt_T,
  "P:i" => \$opt_P, "port:i"       => \$opt_P,
  "C:s" => \$opt_C, "cluster:s"    => \$opt_C,
  # asnmtap - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "H=s" => \$opt_H, "hostname=s"   => \$opt_H,
  "w=s" => \$opt_w, "warning=s"    => \$opt_w,
  "c=s" => \$opt_c, "critical=s"   => \$opt_c,
  # default - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "t:f" => \$opt_t, "trendline:f"  => \$opt_t,
  "S:s" => \$opt_S, "status:s"     => \$opt_S,
  "D:s" => \$opt_D, "debug:s"      => \$opt_D,
  "L:s" => \$opt_L, "logging:s"    => \$opt_L,
  "d:s" => \$opt_d, "debugfile:s"   => \$opt_d,
  "O:s" => \$opt_O, "onDemand:s"   => \$opt_O,
  "A:s" => \$opt_A, "asnmtapEnv:s" => \$opt_A,
  "V"   => \$opt_V, "version"      => \$opt_V,
  "h"   => \$opt_h, "help"         => \$opt_h
);

if ($opt_V) { printRevision($PROGNAME, $version); exit $ERRORS{"OK"}; }
if ($opt_h) { printHelp(); exit $ERRORS{"OK"}; }
my ($trendline, $status, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $returnCode, $startTime, $onDemand, $asnmtapEnv) = init_plugin ($opt_t, $opt_S, $opt_D, $opt_L, $opt_d, $opt_O, $opt_A);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ($opt_u) { $username = $opt_u; }
if ($opt_p) { $password = $opt_p; }
if ($opt_B) { $database = $opt_B; }
if ($opt_b) { $binlog   = $opt_b; }
if ($opt_T) { $table    = $opt_T; }
if ($opt_P) { $port     = $opt_P; }

if ($opt_C) {
  if ($opt_C eq 'S' || $opt_C eq 'M') {
    $cluster = $opt_C;
  } else {
    usage("Invalid clusters option: $opt_C\n");
  }
}

($opt_H) || usage("Hostname/address not specified\n");
my $hostname = $1 if ($opt_H =~ /([-.A-Za-z0-9]+)/);
($hostname) || usage("Invalid hostname/address: $opt_H\n");

($opt_w) && ($opt_w =~ /^([0-9.]+)$/) && (my $warning  = $1);
($opt_c) && ($opt_c =~ /^([0-9.]+)$/) && (my $critical = $1);

if ( defined $warning && defined $critical ) {
  if ( $critical <= $warning ) {
    print "Critical update time <$critical> should be larger than warning update time <$warning>\n\n";
    printUsage();
    exit $ERRORS{"UNKNOWN"};
  }
} elsif ( defined $warning || defined $critical ) {
  print "Critical update time and warning update time should exist\n\n";
  printUsage();
  exit $ERRORS{"UNKNOWN"};
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my( $dbh, $sth, $ref, @tables, $dtable, $exist, $prepareString );

$dbh = DBI->connect("DBI:mysql:$database:$hostname:$port", "$username", "$password") or errorTrapDBI($status, $debug, $logging, $debugfile, 'Could not connect to MySQL server '.$hostname, "ERROR: $DBI::err ($DBI::errstr)", '');
@tables = $dbh->tables() or errorTrapDBI($status, $debug, $logging, $debugfile, 'No tables found for database '.$database.' on server '.$hostname, '', '');
foreach $dtable (@tables) { if ( $dtable eq "`$table`" ) { $exist = 1; last; } else { $exist = 0;} }

if ( $exist ) {
  $alert = '';
  $state = $STATE{$ERRORS{"OK"}};

  if ( $dbh ) {
    if ( $cluster eq 'S' || $cluster eq 'M' ) {
      $prepareString = "SHOW MASTER STATUS";
      $sth = $dbh->prepare($prepareString) or errorTrapDBI($status, $debug, $logging, $debugfile, 'dbh->prepare $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');
      $sth->execute or errorTrapDBI($status, $debug, $logging, $debugfile, 'sth->execute $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');

      $ref = $sth->fetchrow_arrayref;

      if ( $ref ) { 
	    print "M) File '$$ref[0]' Position '$$ref[1]'\nM) Binlog_do_db '$$ref[2]' Binlog_ignore_db '$$ref[3]'\n" if $debug; 

        if ((index $$ref[2], $binlog) ne -1) {
          $alert .= "+Binlog do DB";
		  print "M) Binlog do DB '$binlog' present\n" if $debug; 
        } else {
		  print "M) Binlog do DB '$binlog' not present\n" if $debug; 
          $alert = "Binlog do DB '$binlog' not present";
          $state = $STATE{$ERRORS{"CRITICAL"}};
	  	}
	  }

      $sth->finish() or errorTrapDBI($status, $debug, $logging, $debugfile, 'sth->finish $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');

      if ( $state eq $STATE{$ERRORS{"OK"}} ) {
        $prepareString = "SHOW SLAVE STATUS";
        $sth = $dbh->prepare($prepareString) or errorTrapDBI($status, $debug, $logging, $debugfile, 'dbh->prepare $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');
        $sth->execute or errorTrapDBI($status, $debug, $logging, $debugfile, 'sth->execute $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');

        $ref = $sth->fetchrow_arrayref;

        if ( $ref ) {
	      print "S) Slave_IO_State '$$ref[0]'\nS) Master_Host '$$ref[1]' Master_User '$$ref[2]'\nS) Master_Port '$$ref[3]' Connect_retry '$$ref[4]'\nS) Master_Log_File '$$ref[5]' Read_Master_Log_Pos '$$ref[6]'\nS) Relay_Log_File '$$ref[7]' Relay_Log_Pos '$$ref[8]'\nS) Relay_Master_Log_File '$$ref[9]' Slave_IO_Running '$$ref[10]'\nS) Slave_SQL_Running '$$ref[11]' Replicate_do_db '$$ref[12]'\nS) Replicate_ignore_db '$$ref[13]' Replicate_Do_Table '$$ref[14]'\nS) Replicate_Ignore_Table '$$ref[15]' Replicate_Wild_Do_Table '$$ref[16]'\nS) Replicate_Wild_Ignore_Table '$$ref[17]' Last_errno '$$ref[18]'\nS) Last_error '$$ref[19]' Skip_counter '$$ref[20]'\nS) Exec_master_log_pos '$$ref[21]' Relay_log_space '$$ref[22]'\n" if $debug;

          if ((index $$ref[12], $binlog) ne -1) {
            if ( $cluster eq 'M' ) {
              print "S) Replication for '$binlog' running on master server\n" if $debug; 
              $alert = "Replication for '$binlog' running on master server";
              $state = $STATE{$ERRORS{"WARNING"}};
            } else {
              if ($$ref[11] eq 'No') {
                print "S) Replication ERROR: NO Slave SQL Running\n" if $debug; 
                $alert = "Replication ERROR: NO Slave SQL Running";
                $state = $STATE{$ERRORS{"CRITICAL"}};
              } elsif ($$ref[18] ne '') {
                print "S) Replication ERROR '$$ref[18]' for '$binlog' running on slave server\n" if $debug; 
                $alert = "Replication ERROR '$$ref[18]' for '$binlog' running on slave server";
                $state = $STATE{$ERRORS{"CRITICAL"}};
              } else {
                $alert .= "+Replicate do DB+" . $$ref[0];
      	        print "S) Replicate do DB '$binlog' present\n" if $debug; 
              }
            }
          } else {
	        print "S) Replicate do DB '$binlog' not present\n" if $debug; 
            $alert = "Replicate do DB '$binlog' not present";
            $state = $STATE{$ERRORS{"CRITICAL"}};
		  }
        } else {
          if ( $cluster eq 'S' ) {
            print "S) Replication for '$binlog' not running on slave server\n" if $debug;
            $alert = "Replication for '$binlog' not running on slave server";
            $state = $STATE{$ERRORS{"WARNING"}};
          }
		}

        $sth->finish() or errorTrapDBI($status, $debug, $logging, $debugfile, 'sth->finish $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');
      }
    }

    if ( $state eq $STATE{$ERRORS{"OK"}} ) {
      $prepareString = "SHOW TABLE STATUS FROM $database";
      $sth = $dbh->prepare($prepareString) or errorTrapDBI($status, $debug, $logging, $debugfile, 'dbh->prepare $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');
      $sth->execute or errorTrapDBI($status, $debug, $logging, $debugfile, 'sth->execute $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');

      while ($ref = $sth->fetchrow_arrayref) {
        if ( $$ref[1] eq $table ) {
          my $updateTime = $$ref[12];

          if ( $debug ) {
            print "T) <DBI:mysql:$database:$hostname:$port><$username><$password><$table>\n";
            my $autoIncrement = $$ref[10];
            my $createTime    = $$ref[11];
            if ( defined $autoIncrement ) { print "T) Auto increment <$autoIncrement>\n"; }
            if ( defined $createTime )    { print "T) Create  Time   <$createTime>\n"; }
            if ( defined $updateTime )    { print "T) Update  Time   <$updateTime>\n"; }

            # for(my $i=0; $i<$sth->{'NUM_OF_FIELDS'}; $i++) {
            #   my $field = $$ref[$i];
            #   if ( defined $field ) { print "<", $field, ">\n"; }
            # }
          }

          if ( defined $updateTime ) { 
            if ( $dbh && defined $warning && defined $critical ) {
		      my (@currentTime, @updateTime, @diffDateTime);
              my ($year, $month, $day, $hour, $min, $sec, undef) = split(/\:/, get_yyyymmddhhmmsswday());
              @currentTime  = ($year, $month, $day, $hour, $min, $sec);
              print "T) Current Time   <$year-$month-$day $hour:$min:$sec>\n" if $debug;
              ($year, $month, $day) = split(/\-/, substr($updateTime, 0, 10));
              ($hour, $min, $sec)   = split(/\:/, substr($updateTime, 11));
              @updateTime   = ($year, $month, $day, $hour, $min, $sec);
              print "T) Update  Time   <$year-$month-$day $hour:$min:$sec>\n" if $debug;
              @diffDateTime = Delta_DHMS(@updateTime, @currentTime); 
              my $difference = ($diffDateTime[1]*3600)+($diffDateTime[2]*60)+$diffDateTime[3];
              print "T) Difference     <$difference> Warning <$warning> Critical <$critical>\n" if $debug;
              if ( $alert ne '' ) { $alert .= "+ "; }
              $alert .= "Last update from table '$table' is $difference seconds ago";

              if ( $difference > $critical ) {
                $state = $STATE{$ERRORS{"CRITICAL"}};
              } elsif ( $difference > $warning ) {
                $state = $STATE{$ERRORS{"WARNING"}};
              }
	  	    }
          } else {
            $alert = "Update time for table '$table' don't exist";
            $state = $STATE{$ERRORS{"CRITICAL"}};
          }
        }
	  }

      $sth->finish() or errorTrapDBI($status, $debug, $logging, $debugfile, 'sth->finish $prepareString', "ERROR: $DBI::err ($DBI::errstr)", '');
    }
  }
} else {
  $alert = "table '$table' don't exist";
  $state = $STATE{$ERRORS{"CRITICAL"}};
}

if ( $dbh ) { $dbh->disconnect or errorTrapDBI($status, $debug, $logging, $debugfile, 'Could not disconnect from MySQL server '.$hostname, "ERROR: $DBI::err ($DBI::errstr)", ''); }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

exit_plugin ( $asnmtapEnv, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, "DBI:mysql:$database:$hostname:$port", $alert, '', '' );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($status, $debug, $logging, $debugfile, $error, $errorDBI, $result) = @_;

  print "DBI:mysql:$database:$hostname:$port, username <$username> password <$password>\n$error\nERROR: $errorDBI\n" if $debug;
  exit_plugin ( $asnmtapEnv, $status, $startTime, $trendline, $debug, $logging, $debugfile, $STATE{$ERRORS{"CRITICAL"}}, "DBI:mysql:$database:$hostname:$port", $error, "$error \n$errorDBI", $result );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printUsage () {
  print "Usage: $PROGNAME [-u <username>] [-p <password>] [-B <database>] [-b <binlog>] [-T <table>] -H hostname [-P #] [-C <cluster>] [-w <warning>] [-c <critical>] $PLUGINUSAGE\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub printHelp () {
  printRevision($PROGNAME, $version);
  print "This is the plugin '$prgtext'\n";
  printUsage();

  print "
-u, --username = <username> (default: asnmtap)
-p, --password = <password> (default: asnmtap)
-B, --database = <database> (default: asnmtap)
-b, --binlog   = <binlog>   (default: asnmtap)
-T, --table    = <table>    (default: events)
-H, --hostname = <hostname>
-P, --port     = <port> (default: 3306)
-C, --cluster  = S|M
   S(lave) : check slave replication on
   M(aster): check master replication on
-w, --warning  = last 'Update Time from Table' seconds ago
-c, --critical = last 'Update Time from Table' seconds ago
";

  support();
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

