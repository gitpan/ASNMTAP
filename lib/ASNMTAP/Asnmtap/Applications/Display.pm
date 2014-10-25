# ----------------------------------------------------------------------------------------------------------
# � Copyright 2000-2010 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2010/mm/dd, v3.002.002, package ASNMTAP::Asnmtap::Applications::Display
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Applications::Display;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);
use Time::Local;

# include the class files - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS :DISPLAY :DBDISPLAY);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Applications::Display::ISA         = qw(Exporter ASNMTAP::Asnmtap::Applications);

  %ASNMTAP::Asnmtap::Applications::Display::EXPORT_TAGS = (ALL          => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
                                                                                $CAPTUREOUTPUT
                                                                                $PREFIXPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                                                %ERRORS %STATE %TYPE

                                                                                &sending_mail

                                                                                $CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND

                                                                                &_checkAccObjRef
                                                                                &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                                                &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                                                &_dumpValue

                                                                                $APPLICATIONPATH $PLUGINPATH

                                                                                $DATABASE $CATALOGID
                                                                                $AWSTATSENABLED
                                                                                $HTTPSPATH $RESULTSPATH $PIDPATH
                                                                                $HTTPSURL $IMAGESURL $RESULTSURL
                                                                                $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                                $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $STATUSHEADER01
                                                                                %COLORS %ICONS %ICONSACK %ICONSUNSTABLE %ICONSRECORD %ENVIRONMENT %SOUND
                                                                                $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                                                                $SERVERTABLCOMMENTS $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT
                                                                                &read_table &get_trendline_from_test
                                                                                &create_header &create_footer &encode_html_entities &decode_html_entities &print_header &print_legend

                                                                                &print_revision &usage &call_system ) ],

                                                           APPLICATIONS => [ qw($APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
                                                                                $CAPTUREOUTPUT
                                                                                $PREFIXPATH $PLUGINPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
                                                                                %ERRORS %STATE %TYPE

                                                                                &print_revision &usage &call_system &sending_mail) ],

                                                           COMMANDS     => [ qw($CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND) ],

                                                          _HIDDEN       => [ qw(&_checkAccObjRef
                                                                                &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
                                                                                &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
                                                                                &_dumpValue) ],

                                                           DISPLAY      => [ qw($APPLICATIONPATH

                                                                                $AWSTATSENABLED
                                                                                $HTTPSPATH $RESULTSPATH $PIDPATH
                                                                                $HTTPSURL $IMAGESURL $RESULTSURL
                                                                                $SERVERSMTP $SMTPUNIXSYSTEM $SERVERLISTSMTP $SENDMAILFROM
                                                                                $NUMBEROFFTESTS $VERIFYNUMBEROK $VERIFYMINUTEOK $STATUSHEADER01
                                                                                %COLORS %ICONS %ICONSACK %ICONSUNSTABLE %ICONSRECORD %ENVIRONMENT %SOUND
                                                                                &read_table &get_trendline_from_test
                                                                                &create_header &create_footer &encode_html_entities &decode_html_entities &print_header &print_legend)],

                                                           DBDISPLAY    => [ qw($DATABASE $CATALOGID $SERVERNAMEREADWRITE $SERVERPORTREADWRITE $SERVERUSERREADWRITE $SERVERPASSREADWRITE
                                                                                $SERVERTABLCOMMENTS $SERVERTABLEVENTS $SERVERTABLEVENTSCHNGSLGDT $SERVERTABLEVENTSDISPLAYDT ) ] );

  @ASNMTAP::Asnmtap::Applications::Display::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Applications::Display::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Applications::Display::VERSION     = do { my @r = (q$Revision: 3.002.002$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

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

ASNMTAP::Asnmtap::Applications::Display is a Perl module that provides a nice object oriented interface for ASNMTAP Display Applications

=head1 Description

ASNMTAP::Asnmtap::Applications::Display Subclass of ASNMTAP::Asnmtap::Applications

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Applications

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2010 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.be]

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

