package Zarn::Network::DataFlowAnalyzer {
    use strict;
    use warnings;
    use PPI;
    use Getopt::Long;
    use Zarn::Network::DataFlow;

    our $VERSION = '0.1.0';

    sub new {
        my ($self, $parameters) = @_;
        my ($syntax_tree, $file);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s'  => \$syntax_tree,
            'file=s' => \$file
        );

        if ($syntax_tree && $file) {
            my $network = Zarn::Network::DataFlow -> new([
                '--ast'  => $syntax_tree,
                '--file' => $file,
            ]);

            my $extract_function_args = sub {
                my ($statement) = @_;

                my @args;
                my $list = $statement -> find_first('PPI::Structure::List');

                if (!$list) {
                    return @args;
                }

                my $symbols = $list -> find('PPI::Token::Symbol') || [];
                push @args, @{$symbols};

                return @args;
            };

            my $get_assignment_value = sub {
                my ($statement) = @_;

                my $equals = $statement -> find_first(sub {
                    $_[1] -> isa('PPI::Token::Operator') && $_[1] -> content() eq q{=}
                });

                if (!$equals) {
                    return;
                }

                my $next_token = $equals;
                my @value_tokens;

                while ($next_token = $next_token -> snext_sibling()) {
                    if ($next_token -> isa('PPI::Token::Structure') && $next_token -> content() eq q{;}) {
                        last;
                    }

                    push @value_tokens, $next_token;
                }

                return \@value_tokens;
            };

            my $add_call_site;
            my $process_function_call;
            my $process_assignment;
            my $process_variable_declaration;
            my $process_statement;
            my $process_statements;

            $add_call_site = sub {
                my ($function_name, $location, $args) = @_;

                $network -> {call_graph_builder} -> {add_call_site} -> ($function_name, $location, $args);

                return;
            };

            $process_function_call = sub {
                my ($statement, $word) = @_;

                my $function_name = $word -> content();
                my $location = $word -> location();

                my @args = $extract_function_args -> ($statement);

                $add_call_site -> ($function_name, $location, \@args);

                my $def_use_analyzer = $network -> {def_use_analyzer};

                for my $arg (@args) {
                    if (ref($arg) eq 'PPI::Token::Symbol') {
                        my $var_name = $arg -> content();
                        $var_name =~ s/\A[\$\@\%]//xms;

                        $def_use_analyzer -> {add_use} -> ($var_name, {
                            location => $arg -> location(),
                            context  => 'function_arg',
                            function => $function_name,
                        });
                    }
                }

                return;
            };

            $process_assignment = sub {
                my ($statement) = @_;

                my $symbol = $statement -> find_first('PPI::Token::Symbol');
                if (!$symbol) {
                    return;
                }

                my $var_name = $symbol -> content();
                $var_name =~ s/\A[\$\@\%]//xms;

                my $location = $symbol -> location();
                my $value = $get_assignment_value -> ($statement);

                my $taint_tracker = $network -> {taint_tracker};
                my $def_use_analyzer = $network -> {def_use_analyzer};

                $def_use_analyzer -> {add_definition} -> ($var_name, {
                    location  => $location,
                    statement => $statement,
                    value     => $value,
                    tainted   => $taint_tracker -> {is_value_tainted} -> ($value),
                });

                return;
            };

            $process_variable_declaration = sub {
                my ($statement) = @_;

                my $symbol = $statement -> find_first('PPI::Token::Symbol');
                if (!$symbol) {
                    return;
                }

                my $var_name = $symbol -> content();
                $var_name =~ s/\A[\$\@\%]//xms;

                my $location = $symbol -> location();
                my $value = $get_assignment_value -> ($statement);

                my $taint_tracker = $network -> {taint_tracker};
                my $def_use_analyzer = $network -> {def_use_analyzer};

                $def_use_analyzer -> {add_definition} -> ($var_name, {
                    location  => $location,
                    statement => $statement,
                    value     => $value,
                    tainted   => $taint_tracker -> {is_value_tainted} -> ($value),
                });

                return;
            };

            $process_statement = sub {
                my ($statement) = @_;

                if ($statement -> isa('PPI::Statement::Variable')) {
                    $process_variable_declaration -> ($statement);
                    return;
                }

                if ($statement =~ /=/xms) {
                    $process_assignment -> ($statement);
                    return;
                }

                my $word = $statement -> find_first('PPI::Token::Word');
                if ($word) {
                    $process_function_call -> ($statement, $word);
                    return;
                }

                return;
            };

            $process_statements = sub {
                my $statements = $syntax_tree -> find(sub {
                    $_[1] -> isa('PPI::Statement') || $_[1] -> isa('PPI::Statement::Variable')
                }) || [];

                for my $statement (@{$statements}) {
                    $process_statement -> ($statement);
                }

                return;
            };

            my $analyzer = {
                ast     => $syntax_tree,
                file    => $file,
                network => $network,
                build_data_flow_graph => sub {
                    $process_statements -> ();
                    $network -> {build_network} -> ();

                    return $network -> {def_use_analyzer} -> {dfg};
                },
                is_tainted => sub {
                    my ($variable_name, $line_number) = @_;

                    return $network -> {taint_tracker} -> {is_tainted} -> ($variable_name, $line_number);
                },
                get_definitions => sub {
                    my ($variable_name) = @_;

                    return $network -> {def_use_analyzer} -> {get_definitions} -> ($variable_name);
                },
                get_uses => sub {
                    my ($variable_name) = @_;

                    return $network -> {def_use_analyzer} -> {get_uses} -> ($variable_name);
                },
                get_aliases => sub {
                    my ($variable_name) = @_;

                    return $network -> {def_use_analyzer} -> {get_aliases} -> ($variable_name);
                },
                add_call_site => $add_call_site,
                get_call_sites => sub {
                    my ($function_name) = @_;

                    return $network -> {call_graph_builder} -> {get_call_sites} -> ($function_name);
                },
            };

            return $analyzer;
        }

        return 0;
    }
}

1;
