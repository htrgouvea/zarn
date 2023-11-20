package Zarn::Sarif {
    use strict;
    use warnings;

     sub new {
        my ($self, @vulnerabilities) = @_;

        my $sarif_data = {
            "\$schema" => "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
            version   => "2.1.0",
            runs      => [{
                tool    => {
                    driver => {
                        name    => "ZARN",
                        version => "0.0.8"
                    }
                },
                results => []
            }]
        };

        foreach my $info (@vulnerabilities) {
            my $result = {
                message => {
                    text => $info -> {title}
                },
                locations => [{
                    physicalLocation => {
                        artifactLocation => {
                            uri => $info -> {file}
                        },
                        region => {
                            startLine => $info -> {line},
                            endLine   => $info -> {row}
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