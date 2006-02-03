# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/29, v3.000.003, package ASNMTAP::IO
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::IO;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%STATE %ERRORS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::IO::ISA         = qw(Exporter);

  %ASNMTAP::IO::EXPORT_TAGS = ( ALL    => [ qw(&scan_socket_info) ],
  
                                SOCKET => [ qw(&scan_socket_info) ] );

  @ASNMTAP::IO::EXPORT_OK   = ( @{ $ASNMTAP::IO::EXPORT_TAGS{ALL} } );
  
  $ASNMTAP::IO::VERSION     = 3.000.003;
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Private subs  = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# sub _checkReadOnly0 { if ( @_ > 0 ) { cluck "Syntax error: Can't change value of read-only function ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
# sub _checkReadOnly1 { if ( @_ > 1 ) { cluck "Syntax error: Can't change value of read-only function ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }
# sub _checkReadOnly2 { if ( @_ > 2 ) { cluck "Syntax error: Can't change value of read-only function ". (caller 1)[3]; exit $ERRORS{UNKNOWN} } }

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub scan_socket_info {
  my ($protocol, $ip_adres, $port, $service, $request, $boolean_unixSystem, $alert, $state, $debug, @arguments) = @_;

  my %defaults = (                                    # XMail POP3 Server
    pop3 => { username          => "username",
              password          => "password",
              serviceReady      => "[XMail [0-9.]+ POP3 Server] service ready",
              passwirdRequired  => "Password required for",
              mailMessages      => "Maildrop has [0-9.]+ messages",
              closingSession    => "[XMail [0-9.]+ POP3 Server] closing session"
            }
  );

  my %parms = (%defaults, @arguments);

  my ($exit, $result, $action, $socketProtocol, $socketTimeout);
  $exit   = 0;
  $action = "<NIHIL>";

  print "\nscan_socket_info : <$protocol><$ip_adres><$port><$service><$request><$alert><$state>\n" if ($debug >= 2);

  if ($protocol eq "tcp" || $protocol eq "udp") { $socketProtocol = $protocol; } else { $socketProtocol = "tcp"; }
  $socketTimeout = 5;

  $SIG{'ALRM'} = sub { alarm 0; $exit = 1 };
  alarm 10; $exit = 0;

  use IO::Socket;

  if ($boolean_unixSystem) {
    $result = IO::Socket::INET->new ('Proto' => $socketProtocol, 'PeerAddr' => $ip_adres, 'PeerPort' => $port, 'Timeout' => $socketTimeout);
  } else {
    $result = IO::Socket::INET->new ('Proto' => $socketProtocol, 'PeerAddr' => $ip_adres, 'PeerPort' => $port);
  }

  if ($result) {
    print "IO::Socket::INET : <$result>\n" if ($debug >= 2);
  } else {
    print "IO::Socket::INET : <NIHIL>\n" if ($debug >= 2);
    $alert .= " Cannot connect to $ip_adres $service";
    if ( $state ne $STATE{$ERRORS{"CRITICAL"}} ) { $state = $STATE{$ERRORS{"CRITICAL"}}; }
    return (0, $alert, $state);
  }

  $result->autoflush(1);

  if ($result && ($socketProtocol eq "tcp")) {
    if ($port == 25 and $service eq "smtp") {
      print "smtp(25) : wait for answer\n" if ($debug >= 2);

      while (<$result>) {
        chomp;

        print "smtp(25) : <$_>\n" if ($debug >= 2);
        if ($exit) { $action = "<TIMEOUT>"; last; }

        SWITCH: {
          if ($_ =~ /^220 /) { print $result "HELP\n"; }
          if ($_ =~ /^211 /) { print $result "QUIT\n"; $action = "OK (211)"; }
          if ($_ =~ /^214 /) { print $result "QUIT\n"; $action = "OK (214)"; }
          if ($_ =~ /^250 /) { print $result "QUIT\n"; $action = "OK (250)"; }
          if ($_ =~ /^421 /) { print $result "QUIT\n"; $action = "OK (421)"; }
          if ($_ =~ /^500 /) { print $result "QUIT\n"; $action = "OK (500)"; }
          if ($_ =~ /^501 /) { print $result "QUIT\n"; $action = "OK (501)"; }
          if ($_ =~ /^502 /) { print $result "QUIT\n"; $action = "OK (502)"; }
          if ($_ =~ /^504 /) { print $result "QUIT\n"; $action = "OK (504)"; }
          if ($_ =~ /^221 /) { $action = "OK (221)"; last; }
        }
      }
    } elsif ($port == 110 and $service eq "pop3") {
      print "pop3(110) : wait for answer\n" if ($debug >= 2);

      while (<$result>) {
        chomp;

        print "pop3(110) : <$_>\n" if ($debug >= 2);
        if ($exit) { $action = "<TIMEOUT>"; last; }

        if ($_ =~ /^\+OK /) {
          SWITCH: {
            # XMail POP3 Server
 			if ($_ =~ /$parms{pop3}{serviceReady}/)     { $action = "USER (POP3)"; print "            $action\n" if ($debug >= 2); print $result "USER $parms{pop3}{username}\r\n"; }
            if ($_ =~ /$parms{pop3}{passwirdRequired}/) { $action = "PASS (POP3)"; print "            $action\n" if ($debug >= 2); print $result "PASS $parms{pop3}{password}\r\n"; }
            if ($_ =~ /$parms{pop3}{mailMessages}/)     { $action = "QUIT (POP3)"; print "            $action\n" if ($debug >= 2); print $result "QUIT\r\n"; }
            if ($_ =~ /$parms{pop3}{closingSession }/)  { $action = "OK (POP3)";   print "            $action\n" if ($debug >= 2); last; }
          }
        } elsif ($_ =~ /^\-ERR /){ $action = "<$_>"; print $result "HELP\n"; last; }
      }
    } else {
      print "tcp : $service($port), no RFC implementation\n" if ($debug >= 2);
    }
  } elsif ($result && $socketProtocol eq "udp") {
    print "udp : $service($port), no RFC implementation\n" if ($debug >= 2);
  }

  alarm 0;
  $SIG{'ALRM'} = 'IGNORE';                    # $SIG{'ALRM'} = 'DEFAULT';
  close($result);

  if ($request) { $result = "$request"; } else { $result = "$service($port)"; }

  if ($result eq $action) {
    return (1, $alert, $state);
  } else {
    $alert .= " Wrong answer from $ip_adres $service: $action";
    if ( $state ne $STATE{$ERRORS{"CRITICAL"}} ) { $state = $STATE{$ERRORS{"WARNING"}}; }
    return (0, $alert, $state);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::IO is a Perl module that provides IO functions used by ASNMTAP and ASNMTAP-based applications and plugins.

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

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut