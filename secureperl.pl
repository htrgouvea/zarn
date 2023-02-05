#!/usr/bin/env perl

use 5.018;
use strict;
use warnings;
use YAML::Tiny;
use Getopt::Long;
use PPI::Document;
use File::Find::Rule;
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
    my $rule       = File::Find::Rule -> new();

    $rule -> or (
        $rule -> new -> directory -> name(".git", $ignore) -> prune -> discard,
        $rule -> new
    );

    $rule -> file() -> nonempty();
    $rule -> name("*.pm", "*.t", "*.pl");

    my @files = $rule -> in($source);

    for my $file (@files) {
        my $document = PPI::Document -> new($file);
        
        $document -> prune("PPI::Token::Pod");
        $document -> prune("PPI::Token::Comment");

        foreach my $token (@{$document -> find("PPI::Token")}) {
            # if ($token -> class() eq "PPI::Token::Quote::Double") {
            #     # check if this is a sink function
            # } 

            foreach my $rule (@{$list_rules}) {
                my $sample   = $rule -> {sample} -> [0];
                my $category = $rule -> {category};
                my $title    = $rule -> {name};

                if (grep {$_ =~ m/$sample/} $token -> content()) {
                    print "[$category] - FILE:$file \t Potential: $title.\n";
                }
            }
        }
    }
}

exit main();