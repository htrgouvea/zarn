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

my @undef_defs = $analyzer -> {get_definitions} -> ();
is(scalar @undef_defs, 0, 'Undefined definitions empty');

my @undef_uses = $analyzer -> {get_uses} -> ();
is(scalar @undef_uses, 0, 'Undefined uses empty');

my @undef_aliases = $analyzer -> {get_aliases} -> ();
is(scalar @undef_aliases, 0, 'Undefined aliases empty');

my $decl_code = <<'PERL';
my $decl;
PERL

my $decl_ast = PPI::Document -> new(\$decl_code);
ok($decl_ast, 'Declaration AST created');

my $decl_analyzer = Zarn::Component::Engine::DefUseAnalyzer -> new([
    '--ast' => $decl_ast,
]);

ok($decl_analyzer, 'Declaration analyzer created');
$decl_analyzer -> {build_chains} -> ();

my @decl_uses = $decl_analyzer -> {get_uses} -> ('decl');
is(scalar @decl_uses, 0, 'Declaration not counted as use');

my $missing_analyzer = Zarn::Component::Engine::DefUseAnalyzer -> new([]);
is($missing_analyzer, 0, 'Missing AST returns 0');

done_testing();
