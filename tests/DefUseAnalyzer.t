use strict;
use warnings;
use Test::More;
use PPI::Document;
use Zarn::Component::Engine::DefUseAnalyzer;

my $code = <<'PERL';
my $value = 1;
my $total = $value + 2;
print $total;
sub show {
    my $arg = shift;
    return $arg;
}
PERL

my $ast = PPI::Document -> new(\$code);
ok($ast, 'AST created');

my $analyzer = Zarn::Component::Engine::DefUseAnalyzer -> new([
    '--ast' => $ast,
]);

ok($analyzer, 'Analyzer created');

$analyzer -> {build_chains} -> ();

my @value_uses = $analyzer -> {get_uses} -> ('value');
is(scalar @value_uses, 1, 'value use recorded');
is($value_uses[0] -> {context}, 'expression', 'value use context');

my @total_uses = $analyzer -> {get_uses} -> ('total');
is(scalar @total_uses, 1, 'total use recorded');
is($total_uses[0] -> {context}, 'function_arg', 'total use context');

my @arg_uses = $analyzer -> {get_uses} -> ('arg');
is(scalar @arg_uses, 1, 'arg use recorded');
is($arg_uses[0] -> {context}, 'expression', 'arg use context');

$analyzer -> {add_definition} -> ('value', {
    location => [1, 1],
    value    => [],
});

my @value_defs = $analyzer -> {get_definitions} -> ('value');
is(scalar @value_defs, 1, 'value definition recorded');

$analyzer -> {add_alias} -> ('value', 'alias');

my @alias_entries = $analyzer -> {get_aliases} -> ('value');
is_deeply(\@alias_entries, ['alias'], 'alias recorded');

my @missing_defs = $analyzer -> {get_definitions} -> ('missing');
is(scalar @missing_defs, 0, 'missing definitions empty');

my @missing_uses = $analyzer -> {get_uses} -> ('missing');
is(scalar @missing_uses, 0, 'missing uses empty');

my @missing_aliases = $analyzer -> {get_aliases} -> ('missing');
is(scalar @missing_aliases, 0, 'missing aliases empty');

done_testing();
