package Zarn::Component::Engine::TaintTracker {
    use strict;
    use warnings;
    use Getopt::Long;
    use List::Util 'any';

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
                "\N{COMMERCIAL AT}ARGV" => 1,
                "\N{DOLLAR SIGN}ENV"   => 1,
                q{STDIN}   => 1,
                q{<>}      => 1,
                q{param}   => 1,
                q{cookie}  => 1,
                q{header}  => 1,
            };

            my $checking_taint = {};

            my $get_reaching_definitions;

            $get_reaching_definitions = sub {
                my ($variable_name, $line_number) = @_;

                my @defs = $def_use_analyzer -> {get_definitions} -> ($variable_name);

                my ($most_recent_def) =
                    reverse sort { $a -> {location} -> [0] <=> $b -> {location} -> [0] }
                    grep { $_ -> {location} -> [0] <= $line_number } @defs;

                return $most_recent_def // (
                    map { $get_reaching_definitions -> ($_, $line_number) }
                    $def_use_analyzer -> {get_aliases} -> ($variable_name)
                );
            };

            my $tracker = {
                def_use_analyzer => $def_use_analyzer,
                taint_sources    => $taint_sources,
                is_tainted => sub {
                    my ($variable_name, $line_number) = @_;

                    return 0 if !$variable_name;

                    my ($def) = grep { $_ -> {tainted} }
                        $get_reaching_definitions -> ($variable_name, $line_number);

                    return $def ? $def -> {location} : 0;
                },
                is_value_tainted => sub {
                    my ($value) = @_;

                    return 0 if ref $value ne 'ARRAY';

                    for my $token (@{$value}) {
                        next if !ref $token;

                        my $content = $token -> content();

                        return 1 if any { $content =~ /\Q$_\E/xms } keys %{$taint_sources};

                        if ($token -> isa('PPI::Token::Symbol')) {
                            my $base_var = $content =~ s/\A[\$\@\%]//xmsr;

                            return 1 if any {
                                (my $src = $_) =~ s/\A[\$\@\%]//xms;
                                $base_var eq $src
                            } keys %{$taint_sources};

                            next if exists $checking_taint -> {$base_var};

                            $checking_taint -> {$base_var} = 1;
                            my @defs = $def_use_analyzer -> {get_definitions} -> ($base_var);
                            if (any { $_ -> {tainted} } @defs) {
                                delete $checking_taint -> {$base_var};
                                return 1;
                            }
                            delete $checking_taint -> {$base_var};
                        }

                        if ($token -> isa('PPI::Structure::Subscript')) {
                            my $prev = $token -> sprevious_sibling();
                            if ($prev && $prev -> isa('PPI::Token::Symbol')) {
                                my $var = $prev -> content();
                                return 1 if any { $var =~ /\Q$_\E/xms } keys %{$taint_sources};
                            }
                        }

                        return 1 if $token -> isa('PPI::Token::Quote::Double') && $content =~ /\$/xms;

                        return 1 if $token -> isa('PPI::Token::Operator') && $token -> content() ne q{=};
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
