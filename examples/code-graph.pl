#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Devel::Graph;
use Data::Dumper;
# use PPI;
# use PPI::Document;
# use PPI::Dumper;

sub main {
    my $file    = $ARGV[0];
    my $grapher = Devel::Graph -> new();
    my $graph   = $grapher -> decompose ($file);
    
    print $graph -> as_ascii();

    print Dumper();
}

main();