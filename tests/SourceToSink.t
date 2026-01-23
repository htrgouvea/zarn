package Tests::SourceToSink;

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use PPI::Document;
use Zarn::Network::Source_to_Sink;

my $code = <<'PERL';
my $input = <STDIN>;
system $input;
PERL

my $syntax_tree = PPI::Document -> new(\$code);
ok($syntax_tree, 'AST created');

my ($fh, $filename) = tempfile();
print $fh $code;
close $fh;

my $rules = [
    {
        name     => 'Missing strict',
        category => 'style',
        message  => 'use strict is required',
        type     => 'absence',
        sample   => ['use strict'],
    },
    {
        name     => 'System call with tainted input',
        category => 'security',
        message  => 'tainted system call',
        sample   => ['system'],
    },
];

my @results = Zarn::Network::Source_to_Sink -> new([
    '--ast'      => $syntax_tree,
    '--rules'    => $rules,
    '--dataflow' => 1,
    '--file'     => $filename,
]);

is(scalar @results, 2, 'Two results returned');

my %results_by_title;
for my $result (@results) {
    $results_by_title{$result -> {title}} = $result;
}

my $absence_result = $results_by_title{'Missing strict'};
ok($absence_result, 'Absence rule result present');
is($absence_result -> {line_sink}, 'n/a', 'Absence rule line sink');

my $presence_result = $results_by_title{'System call with tainted input'};
ok($presence_result, 'Presence rule result present');
is($presence_result -> {line_sink}, 2, 'Presence rule line sink');
is($presence_result -> {line_source}, 1, 'Presence rule line source');

my $missing_params = Zarn::Network::Source_to_Sink -> new([]);
is($missing_params, 0, 'Missing parameters returns 0');

my $extra_code = <<'PERL';
my $input = <STDIN>;
`echo $input`;
`echo hi`;
system
PERL

my $extra_syntax_tree = PPI::Document -> new(\$extra_code);
ok($extra_syntax_tree, 'Extra AST created');

my ($extra_fh, $extra_filename) = tempfile();
print $extra_fh $extra_code;
close $extra_fh;

my $extra_rules = [
    {
        name     => 'Backtick exec',
        category => 'security',
        message  => 'backtick execution',
        sample   => ['echo'],
    },
    {
        name     => 'System call',
        category => 'security',
        message  => 'system call',
        sample   => ['system'],
    },
];

my @extra_results = Zarn::Network::Source_to_Sink -> new([
    '--ast'      => $extra_syntax_tree,
    '--rules'    => $extra_rules,
    '--dataflow' => 1,
    '--file'     => $extra_filename,
]);

is(scalar @extra_results, 1, 'One backtick result returned');
is($extra_results[0] -> {title}, 'Backtick exec', 'Backtick result identified');

my @no_flow_results = Zarn::Network::Source_to_Sink -> new([
    '--ast'      => $extra_syntax_tree,
    '--rules'    => $extra_rules,
    '--dataflow' => 0,
    '--file'     => $extra_filename,
]);

is(scalar @no_flow_results, 0, 'No results without dataflow');

my @missing_file_results = Zarn::Network::Source_to_Sink -> new([
    '--ast'      => $extra_syntax_tree,
    '--rules'    => $extra_rules,
    '--dataflow' => 1,
]);

is(scalar @missing_file_results, 0, 'No results without file for dataflow');

done_testing();
1;
