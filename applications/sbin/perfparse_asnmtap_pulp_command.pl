#! /usr/bin/perl -w
 
use strict;
 
my $file = shift @ARGV;
open FH, ">>$file" or die "'$file' could not be opened for appending\n";
print FH join("\t", @ARGV);
print FH "\n";
close FH;
