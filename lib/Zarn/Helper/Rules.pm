package Zarn::Helper::Rules {
    use strict;
    use warnings;
    use YAML::Tiny;

    our $VERSION = '0.0.3';

    sub new {
        my ($self, $rules) = @_;

        if ($rules) {
            my $yamlfile = YAML::Tiny -> read($rules);
            my @rules    = $yamlfile -> [0] -> {rules};

            return @rules;
        }

        return 0;
    }
}

1;