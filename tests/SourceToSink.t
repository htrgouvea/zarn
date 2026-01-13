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

my $ast = PPI::Document -> new(\$code);
ok($ast, 'AST created');

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
    '--ast'      => $ast,
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

done_testing();
