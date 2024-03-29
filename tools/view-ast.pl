#!/usr/bin/env perl

use 5.030;
use strict;
use warnings;
use PPI;
use Data::Dumper;

sub main {
    my $file = $ARGV[0];

    if ($file) {
        my $document = PPI::Document -> new($file);
        print Dumper($document);
    }
}

main();