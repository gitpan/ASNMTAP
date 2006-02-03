#!/usr/bin/perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/29, v3.000.003, making Asnmtap v3.000.003 compatible
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.000.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_template-WebTransact-with-client-certificate.pl',
  _programDescription => "WebTransact plugin template for testing the '$APPLICATION' with client certificate",
  _programVersion     => '3.000.003',
  _programGetOptions  => ['environment|e:s', 'proxy:s', 'trendline|T:i'],
  _clientCertificate  => { certFile => 'ssl/crt/alex-peeters.crt', keyFile => 'ssl/key/alex-peeters-nopass.key'},
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::WebTransact;

my @URLS = ();
my $objectWebTransact = ASNMTAP::Asnmtap::Plugins::WebTransact->new ( \@URLS );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValue ( message => 'www.citap.be/www.citap.com' );

@URLS = (
  { Method => "GET",  Url => "https://secure.citap.be/certificate", Qs_var => [], Qs_fixed => [], Exp => "Testing Client Certificate", Exp_Fault => ">>>NIHIL<<<", Msg => "Testing Client Certificate", Msg_Fault => "Testing Client Certificate" },
);

my $returnCode = $objectWebTransact->check ( {}, asnmtapInherited => \$objectPlugins, newAgent => 1 );

# methode 2: my
my $urlCom = "https://secure.citap.com/certificate";

@URLS = (
  { Method => "GET",  Url => $urlCom, Qs_var => [], Qs_fixed => [], Exp => "Testing Client Certificate", Exp_Fault => ">>>NIHIL<<<", Msg => "Testing Client Certificate", Msg_Fault => "Testing Client Certificate" },
);

$returnCode = $objectWebTransact->check ( {}, asnmtapInherited => \$objectPlugins, newAgent => 0 );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

undef $objectWebTransact;
$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-WebTransact-with-client-certificate.pl

WebTransact plugin template for testing the 'Application Monitor' with client certificate

The ASNMTAP plugins come with ABSOLUTELY NO WARRANTY.

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
