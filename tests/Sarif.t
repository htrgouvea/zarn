use strict;
use warnings;
use Test::More;
use Zarn::Helper::Sarif;

my @vulnerabilities = (
    {
        title       => 'Vuln1',
        message     => 'This is the first vulnerability.',
        file        => 'file1.pm',
        line_sink   => 10,
        rowchar_sink => 5
    },
    {
        title       => 'Vuln2',
        message     => 'This is the second vulnerability.',
        file        => 'file2.pm',
        line_sink   => 20,
        rowchar_sink => 15
    }
);

my $expected_sarif_data = {
    "\$schema" => "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
    version   => "2.1.0",
    runs      => [{
        tool    => {
            driver => {
                name    => "ZARN",
                informationUri => "https://github.com/htrgouvea/zarn",
                version => "0.1.0"
            }
        },
        results => [
            {
                ruleId => 'Vuln1',
                properties => {
                    title => 'Vuln1'
                },
                message => {
                    text => 'This is the first vulnerability.'
                },
                locations => [{
                    physicalLocation => {
                        artifactLocation => {
                            uri => 'file1.pm'
                        },
                        region => {
                            startLine => 10,
                            startColumn  => 5
                        }
                    }
                }]
            },
            {
                ruleId => 'Vuln2',
                properties => {
                    title => 'Vuln2'
                },
                message => {
                    text => 'This is the second vulnerability.'
                },
                locations => [{
                    physicalLocation => {
                        artifactLocation => {
                            uri => 'file2.pm'
                        },
                        region => {
                            startLine => 20,
                            startColumn  => 15
                        }
                    }
                }]
            }
        ]
    }]
};

my $sarif_data = Zarn::Helper::Sarif->new(@vulnerabilities);

is_deeply($sarif_data, $expected_sarif_data, 'SARIF data structure is correct');

done_testing();