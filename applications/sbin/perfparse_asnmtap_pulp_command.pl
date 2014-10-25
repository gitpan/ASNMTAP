#!/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# � Copyright 2003-2008 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2008/02/13, v3.000.016, perfparse_asnmtap_pulp_command.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $version     = do { my @r = (q$Revision: 3.000.016$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
my $file = shift @ARGV;
open FH, ">>$file" or die "'$file' could not be opened for appending\n";
print FH join("\t", @ARGV);
print FH "\n";
close FH;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

