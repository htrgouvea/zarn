use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use PPI::Document;
use Zarn::Network::DataFlowAnalyzer;

my $code = <<'PERL';
my $input = <STDIN>;
my $copy = $input;
print $copy;
PERL

my $syntax_tree = PPI::Document -> new(\$code);
ok($syntax_tree, 'AST created');

my ($fh, $filename) = tempfile();
print $fh $code;
close $fh;

my $analyzer = Zarn::Network::DataFlowAnalyzer -> new([
    '--ast'  => $syntax_tree,
    '--file' => $filename,
]);

ok($analyzer, 'Analyzer created');

my $data_flow_graph = $analyzer -> {build_data_flow_graph} -> ();
ok($data_flow_graph, 'DFG built');

my @input_defs = $analyzer -> {get_definitions} -> ('input');
is(scalar @input_defs, 1, 'input definition recorded');
ok($input_defs[0] -> {tainted}, 'input definition tainted');

my @copy_defs = $analyzer -> {get_definitions} -> ('copy');
is(scalar @copy_defs, 1, 'copy definition recorded');
ok($copy_defs[0] -> {tainted}, 'copy definition tainted');

my @copy_uses = $analyzer -> {get_uses} -> ('copy');
is(scalar @copy_uses, 1, 'copy use recorded');
is($copy_uses[0] -> {context}, 'function_arg', 'copy use context');

my @print_calls = $analyzer -> {get_call_sites} -> ('print');
is(scalar @print_calls, 1, 'print call recorded');
is($print_calls[0] -> {file}, $filename, 'print call file recorded');

my $print_location = $print_calls[0] -> {location};
is($print_location -> [0], 3, 'print call line recorded');

my $tainted_location = $analyzer -> {is_tainted} -> ('copy', 3);
ok($tainted_location, 'copy tainted at line 3');
is($tainted_location -> [0], 2, 'taint source line recorded');

my $extra_code = <<'PERL';
my $decl;
my $ok = 1;
foo($ok, $decl);
exit;
1 + 2;
if (1 == 1) { }
PERL

my $extra_syntax_tree = PPI::Document -> new(\$extra_code);
ok($extra_syntax_tree, 'Extra AST created');

my ($extra_fh, $extra_filename) = tempfile();
print $extra_fh $extra_code;
close $extra_fh;

my $extra_analyzer = Zarn::Network::DataFlowAnalyzer -> new([
    '--ast'  => $extra_syntax_tree,
    '--file' => $extra_filename,
]);

ok($extra_analyzer, 'Extra analyzer created');
my $extra_data_flow_graph = $extra_analyzer -> {build_data_flow_graph} -> ();
ok($extra_data_flow_graph, 'Extra DFG built');

my @decl_defs = $extra_analyzer -> {get_definitions} -> ('decl');
is(scalar @decl_defs, 1, 'Declaration definition recorded');
ok(!defined $decl_defs[0] -> {value}, 'Declaration has no value tokens');

my @ok_uses = $extra_analyzer -> {get_uses} -> ('ok');
ok(scalar @ok_uses >= 1, 'Function arg use recorded for ok');
ok(grep({ $_ -> {context} eq 'function_arg' } @ok_uses), 'Function arg use context');

my @decl_uses = $extra_analyzer -> {get_uses} -> ('decl');
ok(scalar @decl_uses >= 1, 'Function arg use recorded for decl');

my @exit_calls = $extra_analyzer -> {get_call_sites} -> ('exit');
is(scalar @exit_calls, 1, 'Exit call recorded');
is(scalar @{$exit_calls[0] -> {args}}, 0, 'Exit call has no args');

$extra_analyzer -> {network} -> {def_use_analyzer} -> {add_alias} -> ('ok', 'alias_ok');
my @alias_entries = $extra_analyzer -> {get_aliases} -> ('ok');
is_deeply(\@alias_entries, ['alias_ok'], 'Aliases exposed through analyzer');

done_testing();
