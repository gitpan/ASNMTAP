# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/02/28, v3.000.004, package ASNMTAP::Asnmtap::Applications::Collector Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Applications::Collector;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);
use Time::Local;

# include the class files - - - - - - - - - - - - - - - - - - - - - - - -

use lib qw(/opt/asnmtap/.);
use ASNMTAP::Asnmtap::Applications v3.000.004;
use ASNMTAP::Asnmtap::Applications qw(:DEFAULT :ASNMTAP :COLLECTOR :DBCOLLECTOR);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Exporter;

our @ISA         = qw(Exporter ASNMTAP::Asnmtap::Applications);

our @EXPORT      = qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO);

our @EXPORT_OK   = qw($CAPTUREOUTPUT $PREFIXPATH $PLUGINPATH $PERLCOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND %ERRORS %STATE &scan_socket_info &sending_mail
                      $APPLICATIONPATH

                      $DATABASE 
                      $DEBUGDIR
                      $HTTPSPATH $RESULTSPATH $PIDPATH
                      $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                      $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE 
                      $SERVERTABLCOMMENTS $SERVERTABLEVENTS
                      %COLORSRRD
                      &read_table &get_trendline_from_test
                      &set_doIt_and_doOffline
                      &create_header &create_footer);

our %EXPORT_TAGS = (ASNMTAP     => [qw($CAPTUREOUTPUT $PREFIXPATH $PLUGINPATH $PERLCOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND %ERRORS %STATE &scan_socket_info &sending_mail)],

                    COLLECTOR   => [qw($APPLICATIONPATH

                                       $DEBUGDIR
                                       $HTTPSPATH $RESULTSPATH $PIDPATH
                                       $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                       %COLORSRRD
                                       &read_table &get_trendline_from_test
                                       &set_doIt_and_doOffline
                                       &create_header &create_footer)],

                    DBCOLLECTOR => [qw($DATABASE $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                       $SERVERTABLCOMMENTS $SERVERTABLEVENTS)]);

our $VERSION     = 3.000.004;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Public subs without TAGS  = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Common variables  = = = = = = = = = = = = = = = = = = = = = = = = = = =
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Applications::Collector Subclass of ASNMTAP::Asnmtap::Applications

=head1 Description

ASNMTAP::Asnmtap::Applications::Collector is a Perl module that provides a nice object oriented interface for ASNMTAP Collector Applications

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Applications

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
