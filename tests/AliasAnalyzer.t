use strict;
use warnings;
use Test::More;
use PPI::Document;
use Zarn::Component::Engine::AliasAnalyzer;
use Zarn::Component::Engine::DefUseAnalyzer;

my $code = <<'PERL';
my $source = 1;
my $alias = \$source;
PERL

my $syntax_tree = PPI::Document -> new(\$code);
ok($syntax_tree, 'AST created');

my $def_use_analyzer = Zarn::Component::Engine::DefUseAnalyzer -> new([
    '--ast' => $syntax_tree,
]);

ok($def_use_analyzer, 'Def use analyzer created');

my $alias_analyzer = Zarn::Component::Engine::AliasAnalyzer -> new([
    '--ast'              => $syntax_tree,
    '--def_use_analyzer' => $def_use_analyzer,
]);

ok($alias_analyzer, 'Alias analyzer created');

$alias_analyzer -> {analyze} -> ();

my @source_aliases = $def_use_analyzer -> {get_aliases} -> ('source');
is_deeply(\@source_aliases, ['alias'], 'Alias recorded for source');

my @alias_aliases = $def_use_analyzer -> {get_aliases} -> ('alias');
is_deeply(\@alias_aliases, ['source'], 'Alias recorded for alias');

my $missing_alias_analyzer = Zarn::Component::Engine::AliasAnalyzer -> new([]);
is($missing_alias_analyzer, 0, 'Missing parameters returns 0');

my $extra_code = <<'PERL';
my $value = 1;
my $not_alias = \5;
PERL

my $extra_syntax_tree = PPI::Document -> new(\$extra_code);
ok($extra_syntax_tree, 'Extra AST created');

my $extra_def_use = Zarn::Component::Engine::DefUseAnalyzer -> new([
    '--ast' => $extra_syntax_tree,
]);

ok($extra_def_use, 'Extra def use analyzer created');

my $extra_alias_analyzer = Zarn::Component::Engine::AliasAnalyzer -> new([
    '--ast'              => $extra_syntax_tree,
    '--def_use_analyzer' => $extra_def_use,
]);

ok($extra_alias_analyzer, 'Extra alias analyzer created');
$extra_alias_analyzer -> {analyze} -> ();

my @value_aliases = $extra_def_use -> {get_aliases} -> ('value');
is(scalar @value_aliases, 0, 'No aliases recorded for non-symbol casts');

done_testing();
1;
