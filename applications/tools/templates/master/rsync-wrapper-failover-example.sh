#!/usr/bin/perl
# ------------------------------------------------------------------------------
# � Copyright 2003-2006 Alex Peeters [alex.peeters@citap.be]
# ------------------------------------------------------------------------------
# rsync-wrapper-failover.sh for asnmtap, v2.002.xxx - wrapper script for rsync
#   execution via ssh key for use with rsync-mirror-failover.sh
#
#   rsync-wrapper-failover.sh need to be installed onto the master server into /opt/asnmtap-3.000.xxx/applications/master and
#   rsync-mirror-failover.sh & rsync-mirror-failover.conf onto the slave server into /opt/asnmtap-3.000.xxx/applications/slave
#
#   Accepted rsync calls are as follows:
#     rsync --server --sender --delete --delete-after @options . $chrootDir/../../otherdir would succeed
#
#   '../' are forbidden into a directory of filename for security reasons !!!
# ------------------------------------------------------------------------------
# vi hosts.allow
# rsync: <hostname slave failover servers>
#
# vi hosts.deny
# rsync: ALL
# ------------------------------------------------------------------------------

use strict;

# Chroot Dir
my $chrootDir = '/opt/asnmtap-3.000.xxx/results/';

# Where to log successes and failures to set to /dev/null to turn off logging.
my $filename = '/opt/asnmtap-3.000.xxx/log/asnmtap/rsync-wrapper-failover.log';

# What you want sent if access is denied.
my $denyString = 'Access Denied! Sorry';

# The real path of rsync.
my $rsyncPath = '/usr/bin/rsync';

# 1 = 'capture_exec("$system_action")' or 0 = 'system ("$system_action")'
my $captureOutput = 0;

# ------------------------------------------------------------------------------
# DON'T TOUCH BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING!
# ------------------------------------------------------------------------------

my @options = ('-logDtpr',   '-nlogDtpr',   '-vlogDtpr',   '-vnlogDtpr',
               '-logDtprz',  '-nlogDtprz',  '-vlogDtprz',  '-vnlogDtprz',
               '-logDtprc',  '-nlogDtprc',  '-vlogDtprc',  '-vnlogDtprc',
               '-logDtprcz', '-nlogDtprcz', '-vlogDtprcz', '-vnlogDtprcz');

my $TRUE  = (0 == 0);
my $FALSE = (0 == 1);

my $debug = $FALSE;

# ------------------------------------------------------------------------------

my ($rvOpen, $dummy, $argPos);

$rvOpen = open (SSHOUT, "+>>$filename");

unless ( $rvOpen ) {
  print STDERR "Couldn't open log '$filename'!\n";
  exit 0;
}

my $now = localtime;

# Unset the path, so all commands must have the full path. This avoids any path attacks.
delete $ENV{PATH};

# Since this script is called as a forced command, need to get the original rsync command given by the client.

(my $command = $ENV{SSH_ORIGINAL_COMMAND}) || print SSHOUT ("$now environment variable SSH_ORIGINAL_COMMAND not set\n");

unless ( $command ) { print "$now $denyString\n"; close (SSHOUT); exit 1; }

# Log the command for tracking and debugging purposes
print SSHOUT ("$now EVALUATING: $command\n") if ($debug);

# Split the command string to make an argument list
# Evaluate each argument separately for exactness this will allow easy addition of future rsync calls

my @rsync_argv = split /[ \t]+/, $command;
my $ok = $TRUE;

print SSHOUT ("ARG0 = $rsync_argv[0]\n") if ($debug);
print SSHOUT ("ARG1 = $rsync_argv[1]\n") if ($debug);
print SSHOUT ("ARG2 = $rsync_argv[2]\n") if ($debug);
print SSHOUT ("ARG3 = $rsync_argv[3]\n") if ($debug);
print SSHOUT ("ARG4 = $rsync_argv[4]\n") if ($debug);
print SSHOUT ("ARG5 = $rsync_argv[5]\n") if ($debug);
print SSHOUT ("ARG6 = $rsync_argv[6]\n") if ($debug);
print SSHOUT ("ARG7 = $rsync_argv[7]\n") if ($debug && $rsync_argv[2] eq '--sender');

# ARG[0] Complain if the command is not "rsync".
unless ($rsync_argv[0] eq 'rsync') {
  print SSHOUT ("ssh authorized_key account restricted: only rsync allowed\n");
  $ok = $FALSE;
}

# ARG[1] Complain if this arg is not --server
unless ($rsync_argv[1] eq '--server') {
  print SSHOUT ("ARG[1] <$rsync_argv[1]> Failure\n");
  $ok = $FALSE;
}

# ARG[2] Check if this arg is --sender
if ($rsync_argv[2] eq '--sender') {
  $argPos = 3;
} else {
  $argPos = 2;
}

# ARG[$argPos] Complain if this arg is not in @options
my $option;
my $teller = 0;

foreach $option (@options) { if ($rsync_argv[$argPos] eq $option) { $teller++; } }

unless ( $teller != 0 )  {
  print SSHOUT ("ARG[$argPos] <$rsync_argv[$argPos]> Failure\n");
  $ok = $FALSE;
}

# ARG[$argPos] Complain if this arg is not --delete
$argPos++;
unless ($rsync_argv[$argPos] eq '--delete') {
  print SSHOUT ("ARG[$argPos] <$rsync_argv[$argPos]> Failure\n");
  $ok = $FALSE;
}

# ARG[$argPos] Complain if this arg is not --delete-after
$argPos++;
unless ($rsync_argv[$argPos] eq '--delete-after') {
  print SSHOUT ("ARG[$argPos] <$rsync_argv[$argPos]> Failure\n");
  $ok = $FALSE;
}

# ARG[$argPos] Complain if this arg is not .
$argPos++;
unless ($rsync_argv[$argPos] eq '.') {
  print SSHOUT ("ARG[$argPos] <$rsync_argv[$argPos]> Failure\n");
  $ok = $FALSE;
}

# ARG[$argPos] Complain if this arg does not begin with $chrootDir
# SECURITY ISSUE: need to lock down further, $chrootDir/../../otherdir would succeed
$argPos++;
my $log_substr = substr ("$rsync_argv[$argPos]", 0, length($chrootDir));

unless ($log_substr eq $chrootDir && ((index $rsync_argv[$argPos], '../') eq -1)) {
  print SSHOUT ("ARG[7] <$rsync_argv[$argPos]> Failure\n");
  $ok = $FALSE;
}

# If we're OK, run the rsync
$now = localtime;

if ( $ok ) {
  print SSHOUT ("$now RSYNC REQUEST PASSED INSPECTION - INITIATING RSYNC\n") if ($debug);

  # Interesting issue here, printing is queued until file is closed
  # if rsync fails and exits out of the script earlier input would never
  # be seen. In fact 'exec' call was replaced with 'system' call for the
  # reason that exec did not return to the shell and the print output was
  # never seen because the close was never reached.

  # close and reopen output file to empty print queue to this point
  close (SSHOUT);
  $rvOpen = open (SSHOUT, "+>>$filename");

  unless ( $rvOpen ) {
    print STDERR "Couldn't reopen log '$filename'!\n";
    exit 0;
  }

  my ($stdout, $stderr, $exit_value, $signal_num, $dumped_core);
  #remove the first argument which is the rsync command and use absolute path
  shift @rsync_argv;

# if ($captureOutput) {
#   use IO::CaptureOutput qw(capture_exec);
#   ($stdout, $stderr) = capture_exec("$rsyncPath @rsync_argv");
# } else {
    system ("$rsyncPath @rsync_argv"); $stdout = $stderr = '';
# }

  $exit_value  = $? >> 8;
  $signal_num  = $? & 127;
  $dumped_core = $? & 128;

  $now = localtime;

  if ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' ) {
    print SSHOUT ("$now RSYNC COMPLETE\n\n") if ($debug);
  } else {
    print SSHOUT ("$now RSYNC FAILED: $stderr\n\n");
  }
} else {
  print SSHOUT ("$now RSYNC REQUEST FAILED INSPECTION - SKIPPING RSYNC\n");
}

close (SSHOUT);

# ------------------------------------------------------------------------------
