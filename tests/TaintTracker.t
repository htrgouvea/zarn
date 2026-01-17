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

is($tracker -> {is_tainted} -> (undef, 1), 0, 'Missing variable not tainted');
is($tracker -> {is_value_tainted} -> (undef), 0, 'Undefined value not tainted');
is($tracker -> {is_value_tainted} -> ('not_array'), 0, 'Non-array value not tainted');
is($tracker -> {is_value_tainted} -> (['literal']), 0, 'Non-ref token skipped');

$def_use_analyzer -> {add_definition} -> ('tainted_var', {
    location => [1, 1],
    tainted  => 1,
});

$def_use_analyzer -> {add_definition} -> ('plain_var', {
    location => [1, 1],
    tainted  => 0,
});

my $extra_code = <<'PERL';
my $tainted_var = 1;
my $plain_var = 2;
my $interpolated = "$user";
my $env = $ENV{PATH};
my $sum = 1 + 2;
PERL

my $extra_ast = PPI::Document -> new(\$extra_code);
ok($extra_ast, 'Extra AST created');

my $tainted_symbol = $extra_ast -> find_first(sub {
    $_[1] -> isa('PPI::Token::Symbol') && $_[1] -> content() eq '$tainted_var'
});
ok($tainted_symbol, 'Tainted symbol token found');
ok($tracker -> {is_value_tainted} -> ([$tainted_symbol]), 'Symbol tainted via definition');

my $plain_symbol = $extra_ast -> find_first(sub {
    $_[1] -> isa('PPI::Token::Symbol') && $_[1] -> content() eq '$plain_var'
});
ok($plain_symbol, 'Plain symbol token found');
is($tracker -> {is_value_tainted} -> ([$plain_symbol]), 0, 'Symbol without tainted definition not tainted');

my $quote_token = $extra_ast -> find_first('PPI::Token::Quote::Double');
ok($quote_token, 'Double quote token found');
ok($tracker -> {is_value_tainted} -> ([$quote_token]), 'Interpolation taints value');

my $subscript_token = $extra_ast -> find_first('PPI::Structure::Subscript');
ok($subscript_token, 'Subscript token found');
ok($tracker -> {is_value_tainted} -> ([$subscript_token]), 'Subscript taint source detected');

my $operator_token = $extra_ast -> find_first(sub {
    $_[1] -> isa('PPI::Token::Operator') && $_[1] -> content() eq q{+}
});
ok($operator_token, 'Operator token found');
ok($tracker -> {is_value_tainted} -> ([$operator_token]), 'Non-assignment operator taints value');

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
