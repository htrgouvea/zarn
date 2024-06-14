package Zarn::Helper::Sarif {
    use strict;
    use warnings;

    our $VERSION = '0.0.2';

     sub new {
        my ($self, @vulnerabilities) = @_;

        my $sarif_data = {
            "\$schema" => 'https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json',
            version   => '2.1.0',
            runs      => [{
                tool    => {
                    driver => {
                        name    => 'ZARN',
                        informationUri =>'"https://github.com/htrgouvea/zarn',
                        version => '0.1.0'
                    }
                },
                results => []
            }]
        };

        foreach my $info (@vulnerabilities) {
            my $result = {
                ruleId => $info -> {title},
                properties => {
                    title => $info -> {title}
                },
                message => {
                    text => $info -> {message}
                },
                locations => [{
                    physicalLocation => {
                        artifactLocation => {
                            uri => $info -> {file}
                        },
                        region => {
                            startLine => $info -> {line_sink},
                            startColumn  => $info -> {rowchar_sink}
                        }
                    }
                }]
            };

            push @{$sarif_data -> {runs}[0]{results}}, $result;
        }

        return $sarif_data;
    }
}

1;