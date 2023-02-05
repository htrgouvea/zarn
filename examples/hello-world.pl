#!/usr/bin/ern perl

use 5.018;
use strict;
use warnings;

sub main {
    my $name = $ARGV[0];

    system("echo Hello World, $name !\n");
    
}

main();