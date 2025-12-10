package Zarn::Component::Engine::CallGraphBuilder {
    use strict;
    use warnings;
    use Getopt::Long;

    our $VERSION = '0.1.0';

    sub new {
        my ($self, $parameters) = @_;
        my ($file);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'file=s' => \$file
        );

        if ($file) {
            my $call_graph = {};

            my $builder = {
                file       => $file,
                call_graph => $call_graph,
                add_call_site => sub {
                    my ($function_name, $location, $args) = @_;

                    push @{$call_graph -> {$function_name}}, {
                        location => $location,
                        args     => $args,
                        file     => $file,
                    };

                    return;
                },
                get_call_sites => sub {
                    my ($function_name) = @_;

                    return @{$call_graph -> {$function_name} || []};
                },
            };

            return $builder;
        }

        return 0;
    }
}

1;
