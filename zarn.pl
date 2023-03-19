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
        print "
			\rZarn v0.0.1
			\rCore Commands
			\r==============
			\r\tCommand          Description
			\r\t-------          -----------
			\r\t-s, --source     Configure a source directory to do static analysis
			\r\t-r, --rules      Define YAML file with rules
            \r\t-i, --ignore     Define a file or directory to ignore
			\r\t-h, --help       To see help menu of a module
        \n";

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