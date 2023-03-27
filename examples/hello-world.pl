#!/usr/bin/perl
 
use 5.018;
use strict;
use warnings;

sub main {
    my @namae = $ARGV;

    system ("echo Hello World! @namae");
}

exit main();