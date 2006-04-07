# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/04/xx, v3.000.007, package ASNMTAP::Asnmtap::Plugins::SOAP Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::SOAP;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS %TYPE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::SOAP::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Asnmtap::Plugins::SOAP::EXPORT_TAGS = ( ALL => [ qw(&get_soap_request) ] );

  @ASNMTAP::Asnmtap::Plugins::SOAP::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::SOAP::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::SOAP::VERSION     = 3.000.007;
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_soap_request {
  my %defaults = ( asnmtapInherited  => undef,
                   custom            => undef,
                   customArguments   => undef,
                   proxy             => undef,
                   namespace         => undef,
                   registerNamespace => undef,
                   method            => undef,
                   xmlContent        => undef,
                   params            => undef,
                   cookies           => undef,
                   perfdataLabel     => undef
				 );

  my %parms = (%defaults, @_);

  my $asnmtapInherited = $parms{asnmtapInherited};
  unless ( defined $asnmtapInherited ) { cluck ( 'ASNMTAP::Asnmtap::Plugins::SOAP: asnmtapInherited missing' ); exit $ERRORS{UNKNOWN} }

  unless ( defined $parms{proxy} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter proxy' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $parms{namespace} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter namespace' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $registerNamespace = $parms{registerNamespace};

  if ( defined $registerNamespace ) {
    unless ( ref $registerNamespace eq 'HASH' ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter registerNamespace' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  unless ( defined $parms{method} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter method' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $xmlContent = $parms{xmlContent};

  my $params = $parms{params};

  my $cookies = $parms{cookies};

  unless ( $cookies =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'SOAP parameter cookies must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $parms{perfdataLabel} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter perfdataLabel' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my $browseragent  = $$asnmtapInherited->browseragent ();
  my $timeout       = $$asnmtapInherited->timeout ();

  my $proxySettings = $$asnmtapInherited->getOptionsArgv ( 'proxy' );

  my $debug         = $$asnmtapInherited->getOptionsValue ( 'debug' );

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _soapCheckTransportStatus {
    my ($asnmtapInherited, $service, $debug) = @_;

    my $transportStatus = $service->transport->status;
    print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckTransportStatus: $transportStatus\n" if ($debug);

    if ( $service->transport->is_success ) { 
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{OK}, alert => $transportStatus }, $TYPE{APPEND} );
      return $ERRORS{OK};
    };

    for ( $transportStatus ) {
      /500 Can_t connect to/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{REPLACE} ); return $ERRORS{UNKNOWN}; last; };
      /500 Connect failed/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{REPLACE} ); return $ERRORS{UNKNOWN}; last; };
      /500 proxy connect failed/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{REPLACE} ); return $ERRORS{UNKNOWN}; last; };
      /500 Internal Server Error/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{REPLACE} ); return $ERRORS{UNKNOWN}; last; };
    }

    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => $transportStatus }, $TYPE{REPLACE} ); 
    return $ERRORS{CRITICAL};
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _soapCheckFault {
    my ($asnmtapInherited, $som, $debug) = @_;

    my $faultdetail = $som->faultdetail;
    my $faultcode   = $som->faultcode;
    my $faultstring = $som->faultstring;
    my $faultactor  = $som->faultactor;

    if ( $debug ) {
      print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckFault->faultcode   : ", $faultcode,   "\n" if (defined $faultcode);
      print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckFault->faultdetail : ", $faultdetail, "\n" if (defined $faultdetail);
      print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckFault->faultstring : ", $faultstring, "\n" if (defined $faultstring);
      print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckFault->faultactor  : ", $faultactor,  "\n" if (defined $faultactor);
    }

    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $faultcode }, $TYPE{APPEND} ); 
    return $ERRORS{UNKNOWN};
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if ( $debug >= 4 ) {
    eval "use SOAP::Lite +trace => 'all'";
  } elsif ($debug == 1) {
    eval "use SOAP::Lite +trace => qw( debug )";
  } else {
    eval "use SOAP::Lite";
  }

  my ($alert, $error, $result);

  my $service = new SOAP::Lite
  -> autotype   (1)
  -> readable   (1)
  -> envprefix  ('soapenv')
  -> encprefix  ('soapenc')
  -> xmlschema  ('http://www.w3.org/2001/XMLSchema')
  -> uri        ( $parms{namespace} )
  -> on_action  ( sub { sprintf '%s/%s', @_ } )
  -> on_fault   ( sub { } )
  ;

  if ( defined $parms{registerNamespace} ) {
    while ( my ($key, $value) = each( %{ $parms{registerNamespace} } ) ) {
      $service->serializer->register_ns($key, $value);
    }
  }

  if ( defined $proxySettings ) {
    $service->proxy ( $parms{proxy}, timeout => $timeout, proxy => ['http' => "http://$proxySettings"] );
  } else {
    $service->proxy ( $parms{proxy}, timeout => $timeout );
  }

  $service->transport->agent( $browseragent );
  $service->transport->timeout( $timeout );  
 
  use HTTP::Cookies;
  $service->transport->cookie_jar( HTTP::Cookies->new ) if ( $cookies );

  $service->transport->default_headers->push_header( 'Accept-Language' => "no, en" );
  $service->transport->default_headers->push_header( 'Accept-Charset'  => "iso-8859-1,*,utf-8" );
  $service->transport->default_headers->push_header( 'Accept-Encoding' => "gzip, deflate" );
 
  print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: () -->\n" if ( $debug );
  $$asnmtapInherited->setEndTime_and_getResponsTime ( $$asnmtapInherited->pluginValue ('endTime') );

  my $som = (defined $params and $params ne '') ? (ref $params eq 'ARRAY' ? $service->call( $parms{method} => @$params ) : $service->call( $parms{method} => $params )) : $service->call( $parms{method} );

  my $responseTime = $$asnmtapInherited->setEndTime_and_getResponsTime ( $$asnmtapInherited->pluginValue ('endTime') );
  $$asnmtapInherited->appendPerformanceData ( "'". $parms{perfdataLabel} ."'=". $responseTime ."ms;;;;" );
  print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: () <->\n" if ( $debug );

  my $returnCode = _soapCheckTransportStatus ($asnmtapInherited, $service, $debug);

  if ( $returnCode ) {
    $returnCode = _soapCheckFault ($asnmtapInherited, $som, $debug) if ( defined $som->fault );
  } else {
    unless ( defined $som->fault ) {
      $result = UNIVERSAL::isa($som => 'SOAP::SOM') ? (wantarray ? $som->paramsall : $som->result) : $som;

      if ( $debug ) {
        for ( ref $result ) {
          /^REF$/ &&
            do { 
              for ( ref $$result ) {
                /^ARRAY$/ &&
                  do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: REF ARRAY: @$$result\n"; last; };
                /^HASH$/ &&
                  do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: REF HASH: "; while (my ($key, $value) = each %{ $$result } ) { print "$key => $value "; }; print "\n"; last; };
              }

              last;
            };
          /^ARRAY$/ &&
            do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: ARRAY: @$result\n"; last; };
          /^HASH$/ &&
            do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: HASH: "; while (my ($key, $value) = each %{ $result } ) { print "$key => $value "; }; print "\n"; last; };
          /^SCALAR$/ &&
            do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: REF SCALAR: ", $$result, "\n"; last; };
          print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: SCALAR: ", $result, "\n";
        }
      }

      if ( $returnCode == $ERRORS{OK} and defined $parms{custom} ) {
        $returnCode = ( defined $parms{customArguments} ) ? $parms{custom}->($$asnmtapInherited, $som, $parms{customArguments}) : $parms{custom}->($$asnmtapInherited, $som);
      }
    } else {
      $returnCode = _soapCheckFault ($asnmtapInherited, $som, $debug);
    }
  }

  print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: () <--\n" if ( $debug );
  return ($returnCode, undef) unless ( $returnCode == $ERRORS{OK} and defined $xmlContent );

  use XML::Simple;
  my $xml = XMLin($result);

  unless ( defined $xml ) {
    print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: Error parsing XML formatted data", "\n" if ( $debug );
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'Error parsing XML formatted data' }, $TYPE{APPEND} ); 
    return ($returnCode, undef);
  }

  if ( $debug >= 2 ) {
    print "\nASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: Start XML dump\n";
    use Data::Dumper;
    print Dumper($xml);
    print "\nASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: End XML dump\n";
  }

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'SOAP OK' }, $TYPE{APPEND} ); 
  return ($returnCode, $xml);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::SOAP is a Perl module that provides SOAP functions used by ASNMTAP-based plugins.

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

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
