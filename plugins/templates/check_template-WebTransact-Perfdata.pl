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
  _programName        => 'check_template-WebTransact-Perfdata.pl',
  _programDescription => "WebTransact plugin template for testing the '$APPLICATION' with Performance Data",
  _programVersion     => '3.000.003',
  _programGetOptions  => ['environment|e:s', 'proxy:s', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::WebTransact;

my @URLS = ();
my $objectWebTransact = ASNMTAP::Asnmtap::Plugins::WebTransact->new ( \@URLS );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValue ( message => 'www.citap.be/www.citap.com perfdata' );

@URLS = (
  { Method => "GET", Url => "http://www.citap.be/",  Qs_var => [], Qs_fixed => [], Exp => "Consulting Internet Technology Alex Peeters", Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters" },
  { Method => "GET", Url => "http://www.citap.be/",  Qs_var => [], Qs_fixed => [], Exp => "Consulting Internet Technology Alex Peeters", Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => "www.citap.be" },

  { Method => "GET", Url => "http://www.citap.com/", Qs_var => [], Qs_fixed => [], Exp => "Consulting Internet Technology Alex Peeters", Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters" },
  { Method => "GET", Url => "http://www.citap.com/", Qs_var => [], Qs_fixed => [], Exp => "Consulting Internet Technology Alex Peeters", Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => "www.citap.com" },
);

$objectWebTransact->check ( {}, asnmtapInherited => \$objectPlugins );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

undef $objectWebTransact;
$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-WebTransact-Perfdata.pl

WebTransact plugin template for testing the 'Application Monitor' with Performance Data

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
