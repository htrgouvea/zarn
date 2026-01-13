use strict;
use warnings;
use Test::More;
use Zarn::Component::Engine::CallGraphBuilder;

my $builder = Zarn::Component::Engine::CallGraphBuilder -> new([
    '--file' => 'example.pl',
]);

ok($builder, 'Builder created');

$builder -> {add_call_site} -> ('print', [2, 1], ['value']);
$builder -> {add_call_site} -> ('print', [4, 3], ['other']);

my @print_calls = $builder -> {get_call_sites} -> ('print');
is(scalar @print_calls, 2, 'Call sites recorded');
is($print_calls[0] -> {file}, 'example.pl', 'File recorded');

my $no_file_builder = Zarn::Component::Engine::CallGraphBuilder -> new([]);
is($no_file_builder, 0, 'Missing file returns 0');

done_testing();
