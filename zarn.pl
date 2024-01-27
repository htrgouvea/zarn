#!/usr/bin/env perl

use 5.030;
use strict;
use warnings;
use lib "./lib/";
use Getopt::Long;
use Zarn::AST;
use Zarn::Files;
use Zarn::Rules;
use Zarn::Sarif;
use JSON;

our $VERSION = '0.0.9';

sub main {
    my $rules = "rules/default.yml";
    my ($source, $ignore, $sarif, @results);

    Getopt::Long::GetOptions (
        "r|rules=s"   => \$rules,
        "s|source=s"  => \$source,
        "i|ignore=s"  => \$ignore,
        "srf|sarif=s" => \$sarif
    );

    if (!$source) {
        print "
          \rZarn v0.0.9
          \rCore Commands
          \r==============
          \r\tCommand          Description
          \r\t-------          -----------
          \r\t-s, --source     Configure a source directory to do static analysis
          \r\t-r, --rules      Define YAML file with rules
          \r\t-i, --ignore     Define a file or directory to ignore
          \r\t-srf, --sarif    Define the SARIF output file
          \r\t-h, --help       To see help menu of a module\n
        \r";

        exit 1;
    }

    my @rules = Zarn::Rules -> new($rules);
    my @files = Zarn::Files -> new($source, $ignore);

    foreach my $file (@files) {
        if (@rules) {
            my @analysis = Zarn::AST -> new ([
                "--file" => $file,
                "--rules" => @rules
            ]);

            push @results, @analysis;
        }
    }

    foreach my $result (@results) {
        my $category = $result -> {category};
        my $file     = $result -> {file};
        my $title    = $result -> {title};
        my $line     = $result -> {line};
        my $rowchar  = $result -> {rowchar};

        print "[$category] - FILE:$file \t Potential: $title. \t Line: $line:$rowchar\n";
    }

    if ($sarif) {
        my $sarif_data = Zarn::Sarif -> new (@results);

        open(my $output, '>', $sarif) or die "Cannot open file '$sarif': $!";
        
        print $output encode_json($sarif_data);
        
        close($output);
    }

    return 0;
}

exit main();