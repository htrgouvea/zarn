package main;

our $VERSION = '0.0.1';

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);
use PPI::Document;
use Zarn::Network::DataFlow;

my $code = <<'PERL';
my $value = 1;
print $value;
PERL

my $syntax_tree = PPI::Document -> new(\$code);
ok($syntax_tree, 'AST created');

my ($fh, $filename) = tempfile();
print $fh $code;
close $fh;

my $network = Zarn::Network::DataFlow -> new([
    '--ast'  => $syntax_tree,
    '--file' => $filename,
]);

ok($network, 'Network created');

my $def_use_analyzer = $network -> {def_use_analyzer};
ok($def_use_analyzer, 'Def use analyzer present');

$network -> {build_network} -> ();

my $data_flow_graph = $def_use_analyzer -> {dfg};
my $value_entries = $data_flow_graph -> {value};

ok($value_entries, 'DFG entries recorded');
is($value_entries -> [0] -> {type}, 'use', 'DFG use entry recorded');

my $missing_network = Zarn::Network::DataFlow -> new([]);
is($missing_network, 0, 'Missing parameters returns 0');

done_testing();
1;
