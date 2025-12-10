package Zarn::Network::Source_to_Sink {
    use strict;
    use warnings;
    use PPI::Find;
    use Getopt::Long;
    use List::Util 'any';
    use PPI::Document;
    use Zarn::Network::DataFlowAnalyzer;

    our $VERSION = '0.1.0';

    sub new {
        my ($self, $parameters) = @_;
        my ($ast, $rules, $use_dataflow, $file, @results);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s'       => \$ast,
            'rules=s'     => \$rules,
            'dataflow=s'  => \$use_dataflow,
            'file=s'      => \$file
        );

        if (!$ast || !$rules) {
            return 0;
        }

        my @absence = grep { $_ -> {type} && $_ -> {type} eq 'absence' } $rules -> @*;

        for my $rule (@absence) {
            my $category = $rule -> {category};
            my $title    = $rule -> {name};
            my $message  = $rule -> {message};

            foreach my $token ($rule -> {sample} -> @*) {
                next if ($ast -> content() =~ m/$token/xms);

                push @results, {
                    category       => $category,
                    title          => $title,
                    message        => $message,
                    line_sink      => 'n/a',
                    rowchar_sink   => 'n/a',
                    line_source    => 'n/a',
                    rowchar_source => 'n/a'
                };
            }
        }

        my @presence = grep { !($_ -> {type}) || $_ -> {type} eq 'presence' } $rules -> @*;

        foreach my $token (@{$ast -> find('PPI::Token') || []}) {
            foreach my $rule (@presence) {
                my @sample   = $rule -> {sample} -> @*;
                my $category = $rule -> {category};
                my $title    = $rule -> {name};
                my $message  = $rule -> {message};

                if (!(any { my $content = $_; scalar(any { $content =~ m/$_/xms } @sample) } $token -> content())) {
                    next;
                }

                my $variable_name;

                if (ref($token) eq 'PPI::Token::QuoteLike::Backtick') {
                    $variable_name = $token -> content() =~ /[\$\@\%](\w+)/xms ? $1 : undef;

                    if (!$variable_name) {
                        next;
                    }
                }

                if (!$variable_name) {
                    my $next_element = $token -> snext_sibling;

                    if (!defined $next_element || !ref $next_element) {
                        next;
                    }

                    $variable_name = $next_element -> content() =~ /[\$\@\%](\w+)/xms ? $1 : undef;

                    if (!$variable_name) {
                        next;
                    }
                }

                my $taint_analysis;

                if ($use_dataflow && $file) {
                    my $df_engine = Zarn::Network::DataFlowAnalyzer -> new([
                        '--ast'  => $ast,
                        '--file' => $file
                    ]);

                    $df_engine -> {build_data_flow_graph} -> ();

                    my $var_token = $ast -> find_first(
                        sub {
                            $_[1] -> isa('PPI::Token::Symbol') and
                            ($_[1] -> content eq "\$$variable_name")
                        }
                    );

                    if ($var_token) {
                        my $location = $var_token -> location();
                        my $line = $location -> [0];

                        $taint_analysis = $df_engine -> {is_tainted} -> ($variable_name, $line);
                    }
                }

                if (!$taint_analysis) {
                    next;
                }

                my ($line_sink, $rowchar_sink) = @{$token -> location};
                my ($line_source, $rowchar_source) = @{$taint_analysis};

                push @results, {
                    category       => $category,
                    title          => $title,
                    message        => $message,
                    line_sink      => $line_sink,
                    rowchar_sink   => $rowchar_sink,
                    line_source    => $line_source,
                    rowchar_source => $rowchar_source
                };
            }
        }

        return @results;
    }
}

1;
