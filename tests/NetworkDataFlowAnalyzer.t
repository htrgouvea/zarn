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

my $ast = PPI::Document -> new(\$code);
ok($ast, 'AST created');

my ($fh, $filename) = tempfile();
print $fh $code;
close $fh;

my $analyzer = Zarn::Network::DataFlowAnalyzer -> new([
    '--ast'  => $ast,
    '--file' => $filename,
]);

ok($analyzer, 'Analyzer created');

my $dfg = $analyzer -> {build_data_flow_graph} -> ();
ok($dfg, 'DFG built');

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

done_testing();
