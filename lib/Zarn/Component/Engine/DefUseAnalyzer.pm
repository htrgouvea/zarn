package Zarn::Component::Engine::DefUseAnalyzer {
    use strict;
    use warnings;
    use Getopt::Long;

    our $VERSION = '0.1.0';

    sub new {
        my ($self, $parameters) = @_;
        my ($ast);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s' => \$ast
        );

        if ($ast) {
            my $def_use_chains = {};
            my $dfg            = {};
            my $aliases        = {};
            my $taint_tracker  = undef;

            my $get_use_context = sub {
                my ($symbol) = @_;

                my $parent = $symbol -> parent();

                if ($parent -> isa('PPI::Statement::Sub')) {
                    return 'function_definition';
                }

                if (my $word = $parent -> find_first('PPI::Token::Word')) {
                    return 'function_arg';
                }

                return 'expression';
            };

            my $add_use;
            $add_use = sub {
                my ($var_name, $use_info) = @_;

                push @{$def_use_chains -> {$var_name} -> {uses}}, $use_info;

                $dfg -> {$var_name} ||= [];

                push @{$dfg -> {$var_name}}, {
                    type     => 'use',
                    location => $use_info -> {location},
                    context  => $use_info -> {context},
                };

                return;
            };

            my $build_def_use_chains = sub {
                my $symbols = $ast -> find('PPI::Token::Symbol') || [];

                for my $symbol (@{$symbols}) {
                    my $var_name = $symbol -> content();
                    $var_name =~ s/\A[\$\@\%]//xms;

                    my $parent = $symbol -> parent();

                    next if $parent -> isa('PPI::Statement::Variable');

                    my $next = $symbol -> snext_sibling();

                    if ($next && $next -> isa('PPI::Token::Operator') && $next -> content() eq q{=}) {
                        next;
                    }

                    $add_use -> ($var_name, {
                        location => $symbol -> location(),
                        context  => $get_use_context -> ($symbol),
                        token    => $symbol,
                    });
                }

                return;
            };

            my $analyzer = {
                ast            => $ast,
                def_use_chains => $def_use_chains,
                dfg            => $dfg,
                aliases        => $aliases,
                taint_tracker  => $taint_tracker,
                set_taint_tracker => sub {
                    my ($tracker) = @_;

                    $taint_tracker = $tracker;

                    return;
                },
                build_chains => sub {
                    $build_def_use_chains -> ();

                    return;
                },
                get_definitions => sub {
                    my ($variable_name) = @_;

                    if (!$variable_name) {
                        return ();
                    }

                    return @{$def_use_chains -> {$variable_name} -> {defs} || []};
                },
                get_uses => sub {
                    my ($variable_name) = @_;

                    if (!$variable_name) {
                        return ();
                    }

                    return @{$def_use_chains -> {$variable_name} -> {uses} || []};
                },
                get_aliases => sub {
                    my ($variable_name) = @_;

                    if (!$variable_name) {
                        return ();
                    }

                    return @{$aliases -> {$variable_name} || []};
                },
                add_definition => sub {
                    my ($var_name, $def_info) = @_;

                    push @{$def_use_chains -> {$var_name} -> {defs}}, $def_info;

                    $dfg -> {$var_name} ||= [];
                    push @{$dfg -> {$var_name}}, {
                        type     => 'definition',
                        location => $def_info -> {location},
                        value    => $def_info -> {value},
                    };

                    return;
                },
                add_use => $add_use,
                add_alias => sub {
                    my ($var1, $var2) = @_;

                    push @{$aliases -> {$var1}}, $var2;
                    push @{$aliases -> {$var2}}, $var1;

                    return;
                },
            };

            return $analyzer;
        }

        return 0;
    }
}

1;
