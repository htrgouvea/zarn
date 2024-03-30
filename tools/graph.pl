#!/usr/bin/env perl

use 5.018;
use strict;
use warnings;
use Devel::Graph;

sub main {
    my $file = $ARGV[0];

    if ($file) {
        my $grapher = Devel::Graph -> new();
        my $decompose   = $grapher -> decompose ($file);
       
        print $decompose -> as_ascii();
    }

    return 0;
}

exit main();