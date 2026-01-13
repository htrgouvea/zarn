use strict;
use warnings;
use Test::More;
use PPI::Document;
use Zarn::Component::Engine::DefUseAnalyzer;
use Zarn::Component::Engine::TaintTracker;

my $code = <<'PERL';
my $value = $ENV{PATH};
my $safe = 'ok';
PERL

my $ast = PPI::Document -> new(\$code);
ok($ast, 'AST created');

my $def_use_analyzer = Zarn::Component::Engine::DefUseAnalyzer -> new([
    '--ast' => $ast,
]);

ok($def_use_analyzer, 'Def use analyzer created');

my $tracker = Zarn::Component::Engine::TaintTracker -> new([
    '--def_use_analyzer' => $def_use_analyzer,
]);

ok($tracker, 'Taint tracker created');

my $statement = $ast -> find_first('PPI::Statement');
my $operator = $statement -> find_first(sub {
    $_[1] -> isa('PPI::Token::Operator') && $_[1] -> content() eq q{=}
});

my @value_tokens;
my $next = $operator;
while ($next = $next -> snext_sibling()) {
    last if $next -> isa('PPI::Token::Structure') && $next -> content() eq q{;};
    push @value_tokens, $next;
}

my $tainted = $tracker -> {is_value_tainted} -> (\@value_tokens);
ok($tainted, 'Value tokens tainted');

my $safe_statement = $ast -> find_first(sub {
    $_[1] -> isa('PPI::Statement') && $_[1] -> content() =~ /\$safe/xms
});

my $safe_operator = $safe_statement -> find_first(sub {
    $_[1] -> isa('PPI::Token::Operator') && $_[1] -> content() eq q{=}
});

my @safe_tokens;
my $safe_next = $safe_operator;
while ($safe_next = $safe_next -> snext_sibling()) {
    last if $safe_next -> isa('PPI::Token::Structure') && $safe_next -> content() eq q{;};
    push @safe_tokens, $safe_next;
}

my $safe_tainted = $tracker -> {is_value_tainted} -> (\@safe_tokens);
is($safe_tainted, 0, 'Safe value not tainted');

$def_use_analyzer -> {add_definition} -> ('input', {
    location => [1, 1],
    tainted  => 1,
});

$def_use_analyzer -> {add_alias} -> ('input', 'alias');

my $tainted_location = $tracker -> {is_tainted} -> ('alias', 2);
ok($tainted_location, 'Alias tainted');
is($tainted_location -> [0], 1, 'Taint line recorded');

my $missing_tracker = Zarn::Component::Engine::TaintTracker -> new([]);
is($missing_tracker, 0, 'Missing parameters returns 0');

done_testing();
