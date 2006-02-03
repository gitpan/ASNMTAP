# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/29, v3.000.002, package ASNMTAP::Asnmtap::Plugins::Modem Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::Modem;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS %TYPE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::Modem::ISA         = qw(Exporter ASNMTAP::Asnmtap::Plugins);

  %ASNMTAP::Asnmtap::Plugins::Modem::EXPORT_TAGS = ( ALL => [ qw() ] );

  @ASNMTAP::Asnmtap::Plugins::Modem::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::Modem::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::Modem::VERSION     = 3.000.002;
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub init_modem {
  my ($PROGNAME, $timeout, $phonebook, $username, $password, $opt_p, $opt_P, $opt_B, $opt_l, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $asnmtapEnv) = @_;

  use Device::Modem;

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _IfaceInfo {
    my ($Info, $Iface) = @_;

    my $Res = "$Iface:\t".($Info->{$Iface}->{'status'} ? 'UP' : 'DOWN')."\n";
    while (my ($Addr, $Mask) = each(%{$Info->{$Iface}->{'inet'}})) { $Res .= sprintf("\tinet %-15s mask $Mask\n", $Addr); };
    $Info->{$Iface}->{'ether'} and $Res .= "\tether ".$Info->{$Iface}->{'ether'}."\n";
    $Info->{$Iface}->{'descr'} and $Res .= "\tdescr '".$Info->{$Iface}->{'descr'}."'\n";
    return $Res;
  };

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _errorTrapModem {
    my ($error_message, $ras_message, $debug) = @_;
    print "$error_message, $ras_message\n" if ($debug);
    return 0;
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _test_modem {
    my ($testAll, $modem, $ok, $not_connected_guess, $phonenumber, $port, $baud, $log, $timeout, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $loglevel, $asnmtapEnv) = @_;

    # test syslog/file logging.
    if ($debug) {
      $modem = Device::Modem->new( port => $port, log => $log, loglevel => 'debug' );
    } else {
      $modem = Device::Modem->new( port => $port, log => $log, loglevel => $loglevel );
    }

    print "Device::Modem->new: <$modem>\n" if ($debug);

    if ( $modem->connect(baudrate => $baud) ) {
      print "Modem is connected to $port serial port\n" if ($debug);
    } else {
      $alert = "Cannot connect to $port serial port!: $!";
      $state = $STATE{$ERRORS{"CRITICAL"}};
      exit_plugin ( $asnmtapEnv, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result );
    }

    # Testing if modem is turned on and available
    if ( $modem->is_active() ) {
      print "Modem is active\n" if ($debug);
    } else {
      $alert = "Modem is turned off, or not functioning ...";
      $state = $STATE{$ERRORS{"CRITICAL"}};
      exit_plugin ( $asnmtapEnv, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result );
    }

	my $answer;

	if ( $testAll ) {
      # Try with AT escape code, send `attention' sequence (+++)
      $answer = '<NIHIL>';
      $answer = $modem->attention();
      $answer = '<no answer>' if ( !(defined $answer) );
      print "Sending attention, modem says '$answer'\n" if ($debug);

      if ( $answer ne '<no answer>' ) {
        $alert .= " Sending attention, modem says '$answer'";
        $not_connected_guess++;
      }

      # Send empty AT command
      $answer = '<NIHIL>';
      $modem->atsend('AT'.Device::Modem::CR);
      $answer = $modem->answer();
      $answer = '<no answer>' if ( !(defined $answer) );
      print "Sending AT, modem says '$answer'\n" if ($debug);

      if ( !($answer =~ /OK/) ) {
        $alert .= " Sending AT, modem says '$answer'";
        $not_connected_guess++;
      }

      # This must generate an error!
      $answer = '<NIHIL>';
      $modem->atsend('AT@x@@!$#'.Device::Modem::CR);
      $answer = $modem->answer();
      $answer = '<no answer>' if ( !(defined $answer) );
      print "Sending erroneous AT command, modem says '$answer'\n" if ($debug);

      if ( !($answer =~ /ERROR/) ) {
        $alert .= " Sending erroneous AT command, modem says '$answer'";
        $not_connected_guess++;
      }

      $answer = '<NIHIL>';
      $modem->atsend('AT'.Device::Modem::CR);
      $modem->answer();
      $answer = '<no answer>' if ( !(defined $answer) );
      print "Sending AT command, modem says '$answer'\n" if ($debug);

      $answer = '<NIHIL>';
      $modem->atsend('ATZ'.Device::Modem::CR);
      $answer = $modem->answer();
      $answer = '<no answer>' if ( !(defined $answer) );
      print "Sending ATZ reset command, modem says '$answer'\n" if ($debug);

      if ( !($answer =~ /OK/ )) {
        $alert .= " Sending ATZ reset command, modem says '$answer'";
        $not_connected_guess++;
      }

      $answer = '<NIHIL>';
      ($ok, $answer) = $modem->dial($phonenumber, $timeout);
      $answer = '<no answer>' if ( !(defined $answer) );

      if ( $ok ) {
        print "Dialed [" . $phonenumber . "], answer <$answer>\n" if ($debug);
      } else {
        $alert .= " Cannot dial [" . $phonenumber . "]";
        print "Cannot dial [" . $phonenumber . "], answer <$answer>\n" if ($debug);
        $not_connected_guess++;
      }

      sleep(1);
    } else {
      undef $modem;
      sleep(1);
    }

	return ($modem, $ok, $answer, $not_connected_guess, $alert, $state);
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my $modemNotRas = ( ($phonebook eq '<NIHIL>') and ($username eq '<NIHIL>') and ($password eq '<NIHIL>') ) ? 1 : 0;

  my $windows;

  if ($^O eq 'MSWin32') {                              # running on Win32
    eval "use Win32::RASE";
    $windows = 1;
  } else {                                             # running on Linix
    eval "use Net::Ifconfig::Wrapper";
    $windows = 0;
  }
 
  # modem settings
  my $port     = ($windows) ? 'com1' : '/dev/ttyS0';
  my $baud     = '19200';

  # loglevel - default logging level. One of: debug, verbose, notice, info, warning, err, crit, alert, emerg
  my $loglevel = 'emerg';
  my $log = 'file,/var/log/asnmtap/' . $PROGNAME . '.log';   # my $log = 'syslog';

  ($opt_p) || usage("Phonenumber not specified\n");
  my $phonenumber = $1 if ($opt_p =~ /([.0-9]+)/);
  ($phonenumber) || usage("Invalid phonenumber: $opt_p\n");

  if ($opt_P) {
    if ($opt_P eq 'com1' || $opt_P eq 'com2' || $opt_P eq '/dev/ttyS0' || $opt_P eq '/dev/ttyS1' ) {
      $port = $opt_P;
    } else {
      usage("Invalid port: $opt_P\n");
    }
  }

  if ($opt_B) {
    if ($opt_B eq '300' || $opt_B eq '1200' || $opt_B eq '2400' || $opt_B eq '4800' || $opt_B eq '9600' || $opt_B eq '19200' || $opt_B eq '38400' || $opt_B eq '57600' || $opt_B eq '115200') {
      $baud = $opt_B;
    } else {
      usage("Invalid baudrate: $opt_B\n");
    }
  }

  if ($opt_l) {
    if ($opt_l eq 'debug' || $opt_l eq 'verbose' || $opt_l eq 'notice' || $opt_l eq 'info' || $opt_l eq 'warning' || $opt_l eq 'err' || $opt_l eq 'crit' || $opt_l eq 'alert' || $opt_l eq 'emerg') {
      $loglevel = $opt_l;
    } else {
      usage("Invalid loglevel: $opt_l\n");
    }
  }

  $Device::Modem::port     = $port;
  $Device::Modem::baudrate = $baud;

  print "Your serial port is `$Device::Modem::port' (environment configured)\n" if ($debug);
  print "Link baud rate   is `$Device::Modem::baudrate' (environment configured)\n" if ($debug);

  my ($modem, $ok, $answer, $not_connected_guess);
  $not_connected_guess = 0;
  ($modem, $ok, $answer, $not_connected_guess, $alert, $state) = _test_modem ( $modemNotRas, $modem, $ok, $not_connected_guess, $phonenumber, $port, $baud, $log, $timeout, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $loglevel, $asnmtapEnv );

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my $hrasconn;

  if ( ! $modemNotRas ) {
    my ($ppp0, $exit);

    if ( $windows ) {
      eval { no strict "subs"; $hrasconn = RasDial($phonebook, $phonenumber, $username, $password) or _errorTrapModem("Cannot DIAL to $phonenumber", Win32::RASE::FormatMessage, $debug) };
    } else {
      call_system ("/sbin/route del default", $debug);

      my $command = "cd /etc/ppp; /usr/sbin/pppd $port $baud debug user $username call $phonebook connect \"/usr/sbin/chat -v ABORT BUSY ABORT 'NO CARRIER' ABORT VOICE ABORT 'NO DIALTONE' ABORT 'NO DIAL TONE' ABORT 'NO ANSWER' ABORT DELAYED '' ATZ OK AT OK ATDT$phonenumber CONNECT '\\d\\c'\" defaultroute";
      print "Command: <$command>\n" if ($debug);

	  my ($rStatus, $rStdout, $rStderr) = call_system ("$command", $debug);

      if ( $rStatus ) {
        $SIG{'ALRM'} = sub { alarm 0; $exit = 1 };
        alarm 60; $exit = 0;

        do {
          my $info; eval { $info = Net::Ifconfig::Wrapper::Ifconfig('list') };
          # my $info = Net::Ifconfig::Wrapper::Ifconfig('list');

          if ( defined $info ) {
            (undef, $ppp0) = split(/:/, _IfaceInfo($info, "ppp0"));
            $_ = $ppp0;
            chomp;
            s/[ \t]+/ /g;
            $ppp0 = $_;
            print "<$ppp0>\n" if ($debug);
            $hrasconn = $phonebook if ($ppp0 =~ /UP/);
          }

          sleep 1;
          undef $info;
        } until (defined $hrasconn || $exit);

        alarm 0;
        $SIG{'ALRM'} = 'IGNORE';             # $SIG{'ALRM'} = 'DEFAULT';

        if ( ! defined $hrasconn ) {
          sleep(1);
          call_system ("killall -HUP pppd", $debug);
          $alert .= " pppd call '$phonebook' failed";
          $not_connected_guess++;
        }
      } else {
       $alert .= " '$command' failed";
       $not_connected_guess++;
      }

      call_system ("/sbin/route -n", $debug);
    }

    if ( defined $hrasconn ) {
      print "Connected, \$hrasconn=$hrasconn\n" if ($debug);

      if ( ! $windows ) {
        my (undef, $pppStatus, $pppdInet, $pppIp, $pppdMask, $pppMask) = split(/ /, $ppp0);
        $alert = " $pppStatus $pppdInet $pppIp $pppdMask $pppMask";
      }
	
	  $ok = 1;
    } else { # modem test
      ($modem, $ok, $answer, $not_connected_guess, $alert, $state) = _test_modem ( ! $modemNotRas, $modem, $ok, $not_connected_guess, $phonenumber, $port, $baud, $log, $timeout, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $loglevel, $asnmtapEnv );

      if ( $windows ) {
        $alert .= " Cannot DIAL to '$phonenumber'";
        $not_connected_guess++;
      }
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print "<$windows><$hrasconn><$modem><$ok><$answer><$not_connected_guess><$alert><$state>\n" if ($debug);
  return ($windows, $hrasconn, $modem, $ok, $answer, $not_connected_guess, $alert, $state);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub exit_modem_plugin {
  my ($windows, $hrasconn, $asnmtapEnv, $defaultGateway, $interface, $phonebook, $modem, $ok, $not_connected_guess, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $performanceData) = @_;

  if ( $phonebook eq '<NIHIL>' ) {
    if ($ok) {
      sleep(1);
      my $ok = $modem->hangup();

      if( $ok =~ /OK/ ) {
        print "Hanging up done\n" if ($debug);
      } else {
        print "Cannot Hanging up\n" if ($debug);
        $alert .= " Cannot Hanging up";
        $not_connected_guess++;
      }
    }
  } else {
    if ( $windows ) {
      eval {
        no strict "subs";

        if ( RasHangUp($hrasconn, 3) ) {
          print "RAS connection was terminated successfully.\n" if ($debug);
        } elsif ( !Win32::RASE::GetLastError ) {
          print "Timeout. RAS connection is still active.\n" if ($debug);
          $alert .= " Timeout. RAS connection is still active.";
          $state = $STATE{$ERRORS{"CRITICAL"}};
        } else {
          print Win32::RASE::FormatMessage, "\n";
          $alert .= " " . Win32::RASE::FormatMessage;
          $state = $STATE{$ERRORS{"CRITICAL"}};
        }
      }
    } else {
      call_system ("/sbin/route del default", $debug);
      call_system ("killall -HUP pppd", $debug);
      call_system ("/sbin/route add default gw $defaultGateway dev $interface", $debug);
    }
  }

  if ( $not_connected_guess++ ) {
    $state = $STATE{$ERRORS{"CRITICAL"}};
  } else {
    if ( $state eq $STATE{$ERRORS{"UNKNOWN"}} ) { $state = $STATE{$ERRORS{"OK"}}; }
  }

  if (defined $performanceData) {
    exit_plugin ( $asnmtapEnv, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result, $performanceData );
  } else {
    exit_plugin ( $asnmtapEnv, $status, $startTime, $trendline, $debug, $logging, $debugfile, $state, $message, $alert, $error, $result );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Modem is a Perl module that provides Modem functions used by ASNMTAP-based plugins.

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Plugins

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
