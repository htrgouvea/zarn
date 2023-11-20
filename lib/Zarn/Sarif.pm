package Zarn::SARIF {
    use strict;
    use warnings;
    use JSON;

     sub new {
        my ($self, $sarif_file, @vulnerabilities) = @_;

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

        open(my $file, '>', $sarif_file) or die "Cannot open file '$sarif_file': $!";
        print $file encode_json($sarif_data);
        close($file);
    }
}

1;