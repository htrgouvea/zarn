package Zarn::Rules{
    use strict;
    use warnings;
    use YAML::Tiny;

    sub new {
        my ($self, $rules) = @_;

        if (!$rules) {
            return undef;
        }

        my $yamlfile = YAML::Tiny->read($rules);

        my $mapped_rules = $yamlfile->[0]->{rules}; 

        return $mapped_rules;
    }
}

1;