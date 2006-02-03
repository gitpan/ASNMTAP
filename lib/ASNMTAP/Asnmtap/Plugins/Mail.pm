# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2006 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2006/01/29, v3.000.003, package ASNMTAP::Asnmtap::Plugins::Mail Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::Mail;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS %TYPE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::Mail::ISA         = qw(Exporter ASNMTAP::Asnmtap::Plugins);

  %ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_TAGS = ( ALL => [ qw() ] );

  @ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::Mail::VERSION     = 3.000.003;
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub sending_fingerprint_mail {
  my ($alert, $state, $serverListSMTP, $mailTo, $mailFrom, $mailSubject, $mailHeader, $mailBranding, $mailTimestamp, $mailStatus, $mailBody, $debug ) = @_;

  use Mail::Sendmail qw(sendmail %mailcfg);
  $mailcfg{port}     = 25;
  $mailcfg{retries}  = 3;
  $mailcfg{delay}    = 1;
  $mailcfg{mime}     = 0;
  $mailcfg{debug}    = $debug;
  $mailcfg{smtp}     = $serverListSMTP;

  my $message = $mailHeader ."\n". $mailBranding ."\n". $mailTimestamp ." ". get_datetimeSignal() ."\n". $mailStatus ."\n". $mailBody ."\n";
  my %mail = ( To => $mailTo, From => $mailFrom, Subject => $mailSubject, Message => $message );
  my $returnCode = (sendmail %mail) ? 1 : 0;
  $state = $STATE{$ERRORS{"CRITICAL"}} if ( !$returnCode and $state ne $STATE{$ERRORS{"CRITICAL"}} );
  print "\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log, "\n" if ($debug);
  return ($returnCode, $alert, $state);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub receiving_fingerprint_mails {
  my ($alert, $state, $serverPOP3, $username, $password, $timeout, $emailsReceivedState, $textFrom, $textTo, $textSubject, $textStatus, $textStatusUp, $textStatusDown, $mailTo, $mailFrom, $mailSubject, $mailHeader, $mailPluginname, $mailBranding, $mailTimestamp, $mailStatus, $popTop, $debug, $functionMailBody, @functionMailBodyArguments ) = @_;

  my ($tDate, $tTime, $result, $numberOfMails, $statusDown, $statusUp, $numberOfMessages);
  $result = $numberOfMails = $statusDown = $statusUp = 0;

  use Net::POP3;
  my $pop = Net::POP3->new($serverPOP3, Timeout => $timeout, Debug => ($debug >= 3) ? 1 : 0);

  if ( ! $pop ) {
    $alert .= " Cannot connect to POP3 server: '$serverPOP3'";
    if ( $state ne $STATE{$ERRORS{"CRITICAL"}} ) { $state = $STATE{$ERRORS{"UNKNOWN"}}; }
  } else {
    $numberOfMessages = $pop->login($username, $password);
  };

  if ( ! defined $numberOfMessages ) {
    $alert .= " Cannot login to the pop3 server: '$serverPOP3'";
    if ( $state ne $STATE{$ERRORS{"CRITICAL"}} ) { $state = $STATE{$ERRORS{"UNKNOWN"}}; }
  } elsif ( $numberOfMessages > 0 ) {
    my $msgnums = $pop->list;

    foreach my $msgnum (keys %$msgnums) {
      print "<- - - - - - - - - - - - - - - - - - - - - - - - - - - - >\n" if ($debug);
      my ($date, $day, $month, $year, $time, $hour, $min, $sec, $msg);
	  $msg = ($popTop) ? $pop->top($msgnum, $popTop) : $pop->top($msgnum);

      my $fromNotFound     = 1;
      my $toNotFound       = 1;
      my $subjectNotFound  = 1;

      my ($messageNotFound, $brandingNotFound, $timestampNotFound, $statusNotFound, $fingerprintFound);

      if ($popTop) {
        $messageNotFound   = 1;
        $brandingNotFound  = 1;
        $timestampNotFound = 1;
        $statusNotFound    = 1;
        $fingerprintFound  = 7;
      } else {
        $messageNotFound   = 0;
        $brandingNotFound  = 0;
        $timestampNotFound = 0;
        $statusNotFound    = 0;
        $fingerprintFound  = 3;
      }

      $result              = "";

      my $msgline;
      my $msglineMerge     = 0;

      my ($mimeVersion, $contentTypeTextPlainCharset, $contentTransferEncoding, $contentDisposition);

      foreach my $msgbuffer (@$msg) {
        chomp ($msgbuffer);
        if ($msgbuffer eq '') { next; }

 	    if ($messageNotFound or ! $popTop) {
          if (!defined $mimeVersion and $msgbuffer =~ /^Mime-Version: (.+)$/i) {
            $mimeVersion = $1;
            print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $mimeVersion >\n" if ($debug);
            next;
          } elsif (!defined $contentTypeTextPlainCharset and $msgbuffer =~ /^Content-type: text\/plain; charset=(.+)$/i) {
            $contentTypeTextPlainCharset = $1;
            print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentTypeTextPlainCharset >\n" if ($debug);
            next;
          } elsif (!defined $contentTransferEncoding and $msgbuffer =~ /^Content-Transfer-Encoding: (.+)$/i) {
            $contentTransferEncoding = $1;
            print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentTransferEncoding >\n" if ($debug);
            next;
          } elsif (!defined $contentDisposition and $msgbuffer =~ /^Content-Disposition: (.+)$/i) {
            $contentDisposition = $1;
            print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentDisposition >\n" if ($debug);
            next;
          }
        }

        if ( defined $contentTransferEncoding ) {            # RFC 1521
          if ( ($contentTransferEncoding =~ /7bit/i )
          or ( $contentTransferEncoding =~ /quoted-printable/i )
          or ( $contentTransferEncoding =~ /base64/i )
          or ( $contentTransferEncoding =~ /8bit/i )
          or ( $contentTransferEncoding =~ /binary/i )
          or ( $contentTransferEncoding =~ /x-token/i ) ) {
            if ($msgbuffer =~ /=$/) {
              $msglineMerge = 1;
              chop($msgbuffer);
              $msgline = $msgbuffer;
              next;
    	    } elsif ($msglineMerge) {
              $msgbuffer = $msgline . $msgbuffer;
              $msglineMerge = 0;
            } 
          }
        }

        $msgline = $msgbuffer;

        if ($fromNotFound) {
          if ($msgline =~ /^$textFrom/) {
            print "From .... : $msgline\n" if ($debug);

            if ($msgline =~ /^$textFrom\s+$mailFrom$/) {
              $fromNotFound = 0;
              $fingerprintFound--;
              print "  (match) : $textFrom $mailFrom\n" if ($debug);
              next;
            }
          }
        }

        if ($toNotFound) {
          if ($msgline =~ /^$textTo/) {
            print "To ...... : $msgline\n" if ($debug);

            if ($msgline =~ /^$textTo\s+$mailTo$/) {
			  $toNotFound = 0;
              $fingerprintFound--;
			  print "  (match) : $textTo $mailTo\n" if ($debug);
  			  next;
		    }
          }
        }

		if ($subjectNotFound) {
          if ($msgline =~ /^$textSubject/) {
            print "Subject . : $msgline\n" if ($debug);

    		if ($msgline =~ /^$textSubject\s+$mailSubject$/) {
			  $subjectNotFound = 0;
              $fingerprintFound--;
			  print "  (match) : $textSubject $mailSubject\n" if ($debug);
			  next;
			}
		  }
        }

		if ($popTop and ! ($fromNotFound or $toNotFound or $subjectNotFound) and $fingerprintFound) {
  		  if ($messageNotFound) {
            if ($msgline =~ /^$mailHeader$/) {
			  $messageNotFound = 0;
              $fingerprintFound--;
  	 	      print "Header .. : $msgline\n  (match) : $msgline\n" if ($debug);
			  next;
		    }
          }

		  if ($brandingNotFound) {
            if ($msgline =~ /^$mailPluginname/) {
              if ($debug) {
                my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
  	            print "Branding  : $msglineDebug\n";
              }

              if ($msgline =~ /^$mailBranding$/) {
			    $brandingNotFound = 0;
                $fingerprintFound--;

                if ($debug) {
                  my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
  		          print "  (match) : $msglineDebug\n";
                }

			    next;
  		      }
		    }
          }

		  if ($timestampNotFound) {
		    if ($msgline =~ /^$mailTimestamp/) {
              (undef, $msgline) = split(/: /, $msgline, 2);
              ($date, $time) = split(/ /, $msgline);
              ($day, $month, $year) = split(/[\/|-]/, $date);
              ($hour, $min, $sec) = split(/:/, $time);
              $timestampNotFound = 0;
              $fingerprintFound--;
              print "Timestamp : $msgline  $date  $time\n  (match) : $msgline $day/$month/$year  $hour:$min:$sec\n" if ($debug);
			  next;
            }
          }

		  if ($fingerprintFound == 1 and $statusNotFound) {
  		    if ($msgline =~ /^$textStatus/) {
              if ($debug) {
                my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
                print "Status .. : $msglineDebug\n";
              }

              if ($msgline =~ /^$textStatus\s*<$textStatusDown>$/) {
                $statusDown++;
                $statusNotFound = 0;
                $fingerprintFound--;
                print "  (match) : $textStatus < $textStatusDown >\n" if ($debug);
                last;
              } elsif ($msgline eq "$textStatus <$textStatusUp>") {
                $statusUp++;
                $statusNotFound = 0;
                $fingerprintFound--;
                print "  (match) : $textStatus < $textStatusUp >\n" if ($debug);
                last;
              }
            }
          }
        }

        if ( $fingerprintFound == 0 ) {
          $result .= "$msgline\n";
          print "- - - - - : $msgline\n" if ($debug);
          last;
        }

		print ". . . . . : $msgline\n" if ($debug >= 2);
      }
	
      if ( $fingerprintFound == 0 ) {
        $msg = $pop->get($msgnum);
        $result = "";
        foreach my $msgline (@$msg) { $result .= $msgline; }

        if ( defined $contentTransferEncoding ) {              # RFC 1521
          if ($contentTransferEncoding =~ /7bit/i ) {
          } elsif ( $contentTransferEncoding =~ /quoted-printable/i ) {
            use MIME::QuotedPrint;
            $result = decode_qp($result);
          } elsif ( $contentTransferEncoding =~ /base64/i ) {
            use MIME::Base64;
            $result = decode_base64($result);
          } elsif ( $contentTransferEncoding =~ /8bit/i ) {
          } elsif ( $contentTransferEncoding =~ /binary/i ) {
          } elsif ( $contentTransferEncoding =~ /x-token/i ) {
          }
        } 

        ($numberOfMails, $alert, $state, $result) = $functionMailBody->($numberOfMails, $alert, $state, $result, $pop, $msgnum, $date, $time, $day, $month, $year, $hour, $min, $sec, $debug, @functionMailBodyArguments);
      }

      undef $date; undef $day; undef $month; undef $year; undef $time; undef $hour; undef $min; undef $sec;
    }

    if ( $numberOfMails == 0 ) {
      $alert .= " No emails received";
      $state = ($emailsReceivedState) ? (($state eq $STATE{$ERRORS{"UNKNOWN"}}) ? $STATE{$ERRORS{"OK"}} : $state) : $STATE{$ERRORS{"CRITICAL"}};
    } else {
      $alert .= " $numberOfMails Email(s) received";
      $state = ($emailsReceivedState) ? $STATE{$ERRORS{"CRITICAL"}} : (($state eq $STATE{$ERRORS{"UNKNOWN"}}) ? $STATE{$ERRORS{"OK"}} : $state);
    }
  } else {
    $alert .= " No emails received";
    $state = ($emailsReceivedState) ? $STATE{$ERRORS{"OK"}} : $STATE{$ERRORS{"CRITICAL"}};
  }

  $pop->quit if ( defined $numberOfMessages );

  return ($alert, $state, $result, $numberOfMails, $statusUp, $statusDown);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub sending_fingerprint_mail_XML {
  my ($alert, $state, $serverListSMTP, $mailTo, $mailFrom, $mailSubject, $mailPlugin, $mailDescription, $mailEnvironment, $mailStatus, $mailBody, $debug ) = @_;

  use Mail::Sendmail qw(sendmail %mailcfg);
  $mailcfg{port}     = 25;
  $mailcfg{retries}  = 3;
  $mailcfg{delay}    = 1;
  $mailcfg{mime}     = 0;
  $mailcfg{debug}    = $debug;
  $mailcfg{smtp}     = $serverListSMTP;

  my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);
  my $mailDate      = "$currentYear/$currentMonth/$currentDay";
  my $mailTime      = "$currentHour:$currentMin:$currentSec";
  my $mailEpochtime = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);

  my $fingerprintXML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE FingerprintEmail SYSTEM \"dtd/FingerprintEmail-1.0.dtd\"><FingerprintEmail><Schema Value=\"1.0\"/><Fingerprint From=\"$mailFrom\" To=\"$mailTo\" Destination=\"ASNMTAP\" Plugin=\"$mailPlugin\" Description=\"$mailDescription\" Environment=\"$mailEnvironment\" Date=\"$mailDate\" Time=\"$mailTime\" Epochtime=\"$mailEpochtime\" Status=\"$mailStatus\" /></FingerprintEmail>";
  my $message = $fingerprintXML ."\n". $mailBody ."\n";

  my %mail = ( To => $mailTo, From => $mailFrom, Subject => $mailSubject, Message => $message );
  my $returnCode = (sendmail %mail) ? 1 : 0;
  $state = $STATE{$ERRORS{"CRITICAL"}} if ( !$returnCode and $state ne $STATE{$ERRORS{"CRITICAL"}} );
  print "\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log, "\n" if ($debug);
  return ($returnCode, $alert, $state);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub receiving_fingerprint_mails_XML {
  my ($alert, $state, $serverPOP3, $username, $password, $timeout, $emailsReceivedState, $textFrom, $textTo, $textSubject, $textStatusUp, $textStatusDown, $mailTo, $mailFrom, $mailSubject, $mailPlugin, $mailDescription, $mailEnvironment, $mailStatus, $popTop, $resultOutOfDate, $debug, $functionMailBody, @functionMailBodyArguments ) = @_;

  my ($tDate, $tTime, $result, $numberOfMails, $statusDown, $statusUp, $numberOfMessages);
  $result = $numberOfMails = $statusDown = $statusUp = 0;

  use Net::POP3;
  my $pop = Net::POP3->new($serverPOP3, Timeout => $timeout, Debug => ($debug >= 3) ? 1 : 0);

  if ( ! $pop ) {
    $alert .= " Cannot connect to POP3 server: '$serverPOP3'";
    if ( $state ne $STATE{$ERRORS{"CRITICAL"}} ) { $state = $STATE{$ERRORS{"UNKNOWN"}}; }
  } else {
    $numberOfMessages = $pop->login($username, $password);
  };

  if ( ! defined $numberOfMessages ) {
    $alert .= " Cannot login to the pop3 server: '$serverPOP3'";
    if ( $state ne $STATE{$ERRORS{"CRITICAL"}} ) { $state = $STATE{$ERRORS{"UNKNOWN"}}; }
  } elsif ( $numberOfMessages > 0 ) {
    use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
    use constant SYSTEM => 'dtd/FingerprintEmail-1.0.dtd';
    use constant FOOTER => '</FingerprintEmail>';
    my $fingerprintXML = HEADER .'<!DOCTYPE FingerprintEmail SYSTEM "'. SYSTEM .'"><FingerprintEmail>';

    my $msgnums = $pop->list;

    foreach my $msgnum (keys %$msgnums) {
      print "<- - - - - - - - - - - - - - - - - - - - - - - - - - - - >\n" if ($debug);
      my ($date, $day, $month, $year, $time, $hour, $min, $sec, $msg);
	  $msg = ($popTop) ? $pop->top($msgnum, $popTop) : $pop->top($msgnum);

      my $fromNotFound     = 1;
      my $toNotFound       = 1;
      my $subjectNotFound  = 1;

      my ($xmlNotFound, $statusNotFound, $fingerprintFound);

      if ($popTop) {
        $xmlNotFound       = 1;
        $statusNotFound    = 1;
        $fingerprintFound  = 5;
      } else {
        $xmlNotFound       = 0;
        $statusNotFound    = 0;
        $fingerprintFound  = 3;
      }

      $result              = "";

      my $msgline;
      my $msglineMerge     = 0;

      my ($mimeVersion, $contentTypeTextPlainCharset, $contentTransferEncoding, $contentDisposition);

      foreach my $msgbuffer (@$msg) {
        chomp ($msgbuffer);
        if ($msgbuffer eq '') { next; }

 	    if ($xmlNotFound or ! $popTop) {
          if (!defined $mimeVersion and $msgbuffer =~ /^Mime-Version: (.+)$/i) {
            $mimeVersion = $1;
            print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $mimeVersion >\n" if ($debug);
            next;
          } elsif (!defined $contentTypeTextPlainCharset and $msgbuffer =~ /^Content-type: text\/plain; charset=(.+)$/i) {
            $contentTypeTextPlainCharset = $1;
            print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentTypeTextPlainCharset >\n" if ($debug);
            next;
          } elsif (!defined $contentTransferEncoding and $msgbuffer =~ /^Content-Transfer-Encoding: (.+)$/i) {
            $contentTransferEncoding = $1;
            print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentTransferEncoding >\n" if ($debug);
            next;
          } elsif (!defined $contentDisposition and $msgbuffer =~ /^Content-Disposition: (.+)$/i) {
            $contentDisposition = $1;
            print "......... : $msgbuffer\n   (MIME) : $msgbuffer < $contentDisposition >\n" if ($debug);
            next;
          }
        }

        if ( defined $contentTransferEncoding ) {            # RFC 1521
          if ( ($contentTransferEncoding =~ /7bit/i )
          or ( $contentTransferEncoding =~ /quoted-printable/i )
          or ( $contentTransferEncoding =~ /base64/i )
          or ( $contentTransferEncoding =~ /8bit/i )
          or ( $contentTransferEncoding =~ /binary/i )
          or ( $contentTransferEncoding =~ /x-token/i ) ) {
            if ($msgbuffer =~ /=$/) {
              $msglineMerge = 1;
              chop($msgbuffer);
              $msgline = $msgbuffer;
              next;
    	    } elsif ($msglineMerge) {
              $msgbuffer = $msgline . $msgbuffer;
              $msglineMerge = 0;
            } 
          }
        }

        $msgline = $msgbuffer;

        if ($fromNotFound) {
          if ($msgline =~ /^$textFrom/) {
            print "From .... : $msgline\n" if ($debug);

            if ($msgline =~ /^$textFrom\s+$mailFrom$/) {
              $fromNotFound = 0;
              $fingerprintFound--;
              print "  (match) : $textFrom $mailFrom\n" if ($debug);
              next;
            }
          }
        }

        if ($toNotFound) {
          if ($msgline =~ /^$textTo/) {
            print "To ...... : $msgline\n" if ($debug);

            if ($msgline =~ /^$textTo\s+$mailTo$/) {
			  $toNotFound = 0;
              $fingerprintFound--;
			  print "  (match) : $textTo $mailTo\n" if ($debug);
  			  next;
		    }
          }
        }

		if ($subjectNotFound) {
          if ($msgline =~ /^$textSubject/) {
            print "Subject . : $msgline\n" if ($debug);

    		if ($msgline =~ /^$textSubject\s+$mailSubject$/) {
			  $subjectNotFound = 0;
              $fingerprintFound--;
			  print "  (match) : $textSubject $mailSubject\n" if ($debug);
			  next;
			}
		  }
        }

		if ($popTop and ! ($fromNotFound or $toNotFound or $subjectNotFound) and $xmlNotFound) {
          if ($msgline =~ /\Q$fingerprintXML\E/) {
			$xmlNotFound = 0;
            $fingerprintFound--;
  	 	    print "XML ..... : $msgline\n  (match) : $msgline\n" if ($debug);

            my ($returnCode, $stateXML, $xml);
            ( $returnCode, $stateXML, $alert, $xml ) = extract_XML($state, $alert, $msgline, undef, HEADER, FOOTER, 1, SYSTEM, $debug);

            if ($returnCode == $ERRORS{'OK'}) {
              if ($xml->{'Fingerprint'}{'From'} eq $mailFrom and $xml->{'Fingerprint'}{'To'} eq $mailTo and $xml->{'Fingerprint'}{'Destination'} eq 'ASNMTAP' and $xml->{'Fingerprint'}{'Plugin'} eq $mailPlugin and $xml->{'Fingerprint'}{'Description'} eq $mailDescription and $xml->{'Fingerprint'}{'Environment'} eq $mailEnvironment) {
                use Date::Calc qw(check_date);
                ($date, $time, $day, $month, $year, $hour, $min, $sec) = 0;

                my $currentTimeslot = timelocal ( (localtime)[0,1,2,3,4,5] );
                my ($checkEpochtime, $checkDate, $checkTime) = ($xml->{'Fingerprint'}{'Epochtime'}, $xml->{'Fingerprint'}{'Date'}, $xml->{'Fingerprint'}{'Time'});
                my ($checkYear, $checkMonth, $checkDay) = split (/\/|-/, $checkDate);
                my ($checkHour, $checkMin, $checkSec) = split (/:/, $checkTime);
                my $xmlEpochtime = timelocal ( $checkSec, $checkMin, $checkHour, $checkDay, ($checkMonth-1), ($checkYear-1900) );
                print "$checkEpochtime, $xmlEpochtime ($checkDate, $checkTime), $currentTimeslot - $checkEpochtime = ". ($currentTimeslot - $checkEpochtime) ." > $resultOutOfDate\n" if ($debug);

                if (! (check_date($checkYear, $checkMonth, $checkDay) or check_time($checkHour, $checkMin, $checkSec))) {
                  $state  = $STATE{$ERRORS{"CRITICAL"}};
                  $alert  = "Date or Time into Fingerprint XML are wrong: $checkDate $checkTime";
                } elsif ( $checkEpochtime != $xmlEpochtime ) {
                  $state  = $STATE{$ERRORS{"CRITICAL"}};
                  $alert  = "Epochtime difference from Date and Time into Fingerprint XML are wrong: $checkEpochtime != $xmlEpochtime ($checkDate $checkTime)";
                } elsif ( $currentTimeslot - $checkEpochtime > $resultOutOfDate * 2 ) {
                  $state  = $STATE{$ERRORS{"CRITICAL"}};
                  $alert  = "Result into Fingerprint XML are out of date: $checkDate $checkTime";
                } elsif ( $currentTimeslot - $checkEpochtime > $resultOutOfDate ) {
                  $state  = $STATE{$ERRORS{"WARNING"}};
                  $alert  = "Result into Fingerprint XML are out of date: $checkDate $checkTime";
                } else {
 				  ($date, $time) = ($checkDate, $checkTime);
                  ($day, $month, $year) = split(/[\/|-]/, $checkDate);
                  ($hour, $min, $sec) = split(/:/, $checkTime);
                }

                if ($xml->{'Fingerprint'}{'Status'} eq $textStatusDown) {
                  $statusDown++;
                  $statusNotFound = 0;
                  $fingerprintFound--;
                  print "  (match) : Status < $textStatusDown >\n" if ($debug);
                  last;
                } elsif ($xml->{'Fingerprint'}{'Status'} eq $textStatusUp) {
                  $statusUp++;
                  $statusNotFound = 0;
                  $fingerprintFound--;
                  print "  (match) : Status < $textStatusUp >\n" if ($debug);
                  last;
                }
              } else {
                if ($debug) {
                  print "  (match) : From ". $xml->{'Fingerprint'}{'From'} ."\n" if ($xml->{'Fingerprint'}{'From'} eq $mailFrom);
                  print "  (match) : To ". $xml->{'Fingerprint'}{'To'} ."\n" if ($xml->{'Fingerprint'}{'To'} eq $mailTo);
                  print "  (match) : Destination ". $xml->{'Fingerprint'}{'Destination'} ."\n" if ($xml->{'Fingerprint'}{'Destination'} eq 'ASNMTAP');
                  print "  (match) : Plugin ". $xml->{'Fingerprint'}{'Plugin'} ."\n" if ($xml->{'Fingerprint'}{'Plugin'} eq $mailPlugin);
                  print "  (match) : Description ". $xml->{'Fingerprint'}{'Description'} ."\n" if ($xml->{'Fingerprint'}{'Description'} eq $mailDescription);
                  print "  (match) : Environment ". $xml->{'Fingerprint'}{'Environment'} ."\n" if ($xml->{'Fingerprint'}{'Environment'} =~ /^$mailEnvironment/i);
                }

                last;
              }
            } else {
              $state = $stateXML;
            }

			next;
		  }
        }

        if ( $fingerprintFound == 0 ) {
          $result .= "$msgline\n";
          print "- - - - - : $msgline\n" if ($debug);
          last;
        }

		print ". . . . . : $msgline\n" if ($debug >= 2);
      }

      if ( $fingerprintFound == 0 ) {
        my $foundFingerprintXML = 0;
        $msg = $pop->get($msgnum);
        $result = "";

        foreach my $msgline (@$msg) {
          if ($foundFingerprintXML) {
            $result .= $msgline;
          } elsif ($msgline =~ /\Q$fingerprintXML\E/) {
            $foundFingerprintXML = 1;
          }
        }

        if ( defined $contentTransferEncoding ) {              # RFC 1521
          if ($contentTransferEncoding =~ /7bit/i ) {
          } elsif ( $contentTransferEncoding =~ /quoted-printable/i ) {
            use MIME::QuotedPrint;
            $result = decode_qp($result);
          } elsif ( $contentTransferEncoding =~ /base64/i ) {
            use MIME::Base64;
            $result = decode_base64($result);
          } elsif ( $contentTransferEncoding =~ /8bit/i ) {
          } elsif ( $contentTransferEncoding =~ /binary/i ) {
          } elsif ( $contentTransferEncoding =~ /x-token/i ) {
          }
        } 

        ($numberOfMails, $alert, $state, $result) = $functionMailBody->($numberOfMails, $alert, $state, $result, $pop, $msgnum, $date, $time, $day, $month, $year, $hour, $min, $sec, $resultOutOfDate, $debug, @functionMailBodyArguments);
      }

      undef $date; undef $day; undef $month; undef $year; undef $time; undef $hour; undef $min; undef $sec;
    }

    if ( $numberOfMails == 0 ) {
      $alert .= " No emails received";
      $state = ($emailsReceivedState) ? (($state eq $STATE{$ERRORS{"UNKNOWN"}}) ? $STATE{$ERRORS{"OK"}} : $state) : $STATE{$ERRORS{"CRITICAL"}};
    } else {
      $alert .= " $numberOfMails Email(s) received";
      $state = ($emailsReceivedState) ? $STATE{$ERRORS{"CRITICAL"}} : (($state eq $STATE{$ERRORS{"UNKNOWN"}}) ? $STATE{$ERRORS{"OK"}} : $state);
    }
  } else {
    $alert .= " No emails received";
    $state = ($emailsReceivedState) ? $STATE{$ERRORS{"OK"}} : $STATE{$ERRORS{"CRITICAL"}};
  }

  $pop->quit if ( defined $numberOfMessages );

  return ($alert, $state, $result, $numberOfMails, $statusUp, $statusDown);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Mail is a Perl module that provides Mail functions used by ASNMTAP-based plugins.

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
