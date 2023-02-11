package Zarn::Rules {
    use strict;
    use warnings;
    use YAML::Tiny;

    sub new {
        my ($self, $rules) = @_;

        if ($rules) {
            my $yamlfile   = YAML::Tiny -> read($rules);
            my @list_rules = $yamlfile -> [0] -> {rules};


            # Add to rules:
            #     context: presence
            #     context: unpresence

            return @list_rules;
        }

        return 0;
    }
}

1;