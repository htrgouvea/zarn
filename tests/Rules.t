package main;

our $VERSION = '0.0.1';

use strict;
use warnings;

use Test::More;
use Zarn::Helper::Rules;
use File::Temp qw(tempfile);

my $yaml_content = <<'END_YAML';
---
rules:
  - rule1
  - rule2
  - rule3
END_YAML

my ($fh, $filename) = tempfile();
print $fh $yaml_content;
close $fh;

my @expected_rules = ('rule1', 'rule2', 'rule3');
my @rules = Zarn::Helper::Rules -> new($filename);

my @flattened_rules = map { @$_ } @rules;
is_deeply(\@flattened_rules, \@expected_rules, 'Rules correctly loaded from YAML file');

my $no_rules = Zarn::Helper::Rules -> new();
is($no_rules, 0, 'Returns 0 when no rules file is provided');

done_testing();
1;
