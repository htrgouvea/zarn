#!/usr/bin/env perl

use 5.018;
use strict;
use warnings;
use YAML::Tiny;
use lib "./lib/";
use Getopt::Long;
use Zarn::Files;
use PPI::Document;
use Data::Dumper;

sub main {
    my ($rules, $source, $ignore);

    Getopt::Long::GetOptions (
        "r|rules=s"  => \$rules,
        "s|source=s" => \$source,
        "i|ignore=s" => \$ignore
    );

    if (!$rules || !$source) {
        print "Usage: $0 -r rules.yml -s source.pl\n";
        exit 1;
    }

    my $yamlfile   = YAML::Tiny -> read($rules);
 	my $list_rules = $yamlfile -> [0];
    
    my @files = Zarn::Files -> new($source, $ignore);

    for my $file (@files) {
        my $document = PPI::Document -> new($file);
        
        $document -> prune("PPI::Token::Pod");
        $document -> prune("PPI::Token::Comment");

        foreach my $token (@{$document -> find("PPI::Token")}) {
            foreach my $rule (@{$list_rules}) {
                my @sample   = $rule -> {sample} -> @*;
                my $category = $rule -> {category};
                my $title    = $rule -> {name};

                if (grep {my $content = $_; scalar(grep {$content =~ m/$_/} @sample)} $token -> content()) {
                    my $next_element = $token -> snext_sibling;

                    # this is a draft source-to-sink function
                    if (defined $next_element && ref $next_element && $next_element -> content =~ /\$/) {
                        print "[$category] - FILE:$file \t Potential: $title.\n";
                    }
                }
            }
        }
    }
}

exit main();
