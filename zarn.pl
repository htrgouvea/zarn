#!/usr/bin/env perl

use 5.018;
use strict;
use warnings;
use lib "./lib/";
use Zarn::AST;
use Zarn::Files;
use Zarn::Rules;
use Getopt::Long;

sub main {
    my $rules = "rules/default.yml";

    my ($source, $ignore);

    Getopt::Long::GetOptions (
        "r|rules=s"  => \$rules,
        "s|source=s" => \$source,
        "i|ignore=s" => \$ignore
    );

    if (!$source) {
        print "Usage: $0 -r rules.yml -s source.pl\n";
        exit 1;
    }

    my @rules = Zarn::Rules -> new($rules);
    my @files = Zarn::Files -> new($source, $ignore);

    foreach my $file (@files) {
        if (@rules) {
            my $analysis = Zarn::AST -> new (["--file" => $file, "--rules" => @rules]);
        }
    }
}

exit main();