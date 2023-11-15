package Zarn::Sarif {
    use strict;
    use warnings;
    use JSON;

    sub new {
        my ($class) = @_;
        my $self = {
            "version" => "2.1.0",
            "runs" => []
        };
        bless $self, $class;
        return $self;
    }

    sub add_run {
        my ($self, $tool_name, $tool_info_uri) = @_;
        push @{$self->{runs}}, {
            "tool" => {
                "driver" => {
                    "name" => $tool_name,
                    "informationUri" => $tool_info_uri
                }
            },
            "results" => []
        };
    }

    sub add_vulnerability {
        my ($self, $run_index, $vulnerability_title, $file_uri, $line) = @_;
        my $result = {
            "ruleId" => $vulnerability_title,
            "message" => {
                "text" => "Vulnerability found: $vulnerability_title"
            },
            "locations" => [
                {
                    "physicalLocation" => {
                        "artifactLocation" => {
                            "uri" => $file_uri
                        },
                        "region" => {
                            "startLine" => $line
                        }
                    }
                }
            ]
        };
        push @{$self->{runs}->[$run_index]->{results}}, $result;
    }

    sub TO_JSON {
        my ($self) = @_;
        return {%$self};
    }

    sub to_json {
        my ($self) = @_;
        my $json = JSON->new->allow_blessed->convert_blessed;
        return $json->encode($self);
    }

    1;
}
