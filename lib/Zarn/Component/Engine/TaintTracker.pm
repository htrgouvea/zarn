package Zarn::Component::Engine::TaintTracker {
    use strict;
    use warnings;
    use Getopt::Long;

    our $VERSION = '0.1.0';

    sub new {
        my ($self, $parameters) = @_;
        my ($def_use_analyzer);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'def_use_analyzer=s' => \$def_use_analyzer
        );

        if ($def_use_analyzer) {
            my $taint_sources = {
                q{@ARGV}  => 1,
                q{$ENV}   => 1,
                q{STDIN}  => 1,
                q{<>}     => 1,
                q{param}  => 1,
                q{cookie} => 1,
                q{header} => 1,
            };

            my $checking_taint = {};

            my $is_definition_tainted = sub {
                my ($def) = @_;

                return $def -> {tainted} || 0;
            };

            my $get_reaching_definitions;

            $get_reaching_definitions = sub {
                my ($variable_name, $line_number) = @_;

                my @defs = $def_use_analyzer -> {get_definitions} -> ($variable_name);
                my @reaching;

                my $most_recent_def = undef;
                my $most_recent_line = 0;

                for my $def (@defs) {
                    my $def_line = $def -> {location} -> [0];
                    if ($def_line <= $line_number && $def_line > $most_recent_line) {
                        $most_recent_def = $def;
                        $most_recent_line = $def_line;
                    }
                }

                if ($most_recent_def) {
                    push @reaching, $most_recent_def;
                }

                if (@reaching == 0) {
                    my @aliases = $def_use_analyzer -> {get_aliases} -> ($variable_name);
                    for my $alias (@aliases) {
                        push @reaching, $get_reaching_definitions -> ($alias, $line_number);
                    }
                }

                return @reaching;
            };

            my $tracker = {
                def_use_analyzer => $def_use_analyzer,
                taint_sources    => $taint_sources,
                is_tainted => sub {
                    my ($variable_name, $line_number) = @_;

                    if (!$variable_name) {
                        return 0;
                    }

                    my @reaching_defs = $get_reaching_definitions -> ($variable_name, $line_number);

                    for my $def (@reaching_defs) {
                        if ($is_definition_tainted -> ($def)) {
                            return $def -> {location};
                        }
                    }

                    return 0;
                },
                is_value_tainted => sub {
                    my ($value) = @_;

                    if (!$value) {
                        return 0;
                    }

                    if (ref $value ne 'ARRAY') {
                        return 0;
                    }

                    for my $token (@{$value}) {
                        if (!ref $token) {
                            next;
                        }

                        my $content = $token -> content();

                        for my $source (keys %{$taint_sources}) {
                            if ($content =~ /\Q$source\E/xms) {
                                return 1;
                            }
                        }

                        if ($token -> isa('PPI::Token::Symbol')) {
                            for my $source (keys %{$taint_sources}) {
                                my $base_var = $content;
                                $base_var =~ s/\A[\$\@\%]//xms;
                                $source =~ s/\A[\$\@\%]//xms;

                                if ($base_var eq $source) {
                                    return 1;
                                }
                            }
                        }

                        if ($token -> isa('PPI::Structure::Subscript')) {
                            my $prev = $token -> sprevious_sibling();
                            if ($prev && $prev -> isa('PPI::Token::Symbol')) {
                                my $var = $prev -> content();
                                for my $source (keys %{$taint_sources}) {
                                    if ($var =~ /\Q$source\E/xms) {
                                        return 1;
                                    }
                                }
                            }
                        }

                        if ($token -> isa('PPI::Token::Symbol')) {
                            my $var_name = $content;
                            $var_name =~ s/\A[\$\@\%]//xms;

                            if (exists $checking_taint -> {$var_name}) {
                                next;
                            }

                            $checking_taint -> {$var_name} = 1;

                            my @defs = $def_use_analyzer -> {get_definitions} -> ($var_name);
                            for my $def (@defs) {
                                if ($def -> {tainted}) {
                                    delete $checking_taint -> {$var_name};
                                    return 1;
                                }
                            }

                            delete $checking_taint -> {$var_name};
                        }

                        if ($token -> isa('PPI::Token::Quote::Double')) {
                            if ($content =~ /\$/xms) {
                                return 1;
                            }
                        }

                        if ($token -> isa('PPI::Token::Operator') && $token -> content() ne q{=}) {
                            return 1;
                        }
                    }

                    return 0;
                },
            };

            return $tracker;
        }

        return 0;
    }
}

1;
