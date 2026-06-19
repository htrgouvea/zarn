package Zarn::Network::Source_to_Sink {
    use strict;
    use warnings;
    use PPI::Find;
    use Getopt::Long;
    use List::Util 'any';
    use PPI::Document;
    use Zarn::Network::DataFlowAnalyzer;

    our $VERSION = '0.1.0';

    sub _process_absence_rules {
        my ($syntax_tree, $rules) = @_;

        my @results;
        my @absence = grep { $_ -> {type} && $_ -> {type} eq 'absence' } $rules -> @*;

        for my $rule (@absence) {
            my $category = $rule -> {category};
            my $title    = $rule -> {name};
            my $message  = $rule -> {message};

            foreach my $token ($rule -> {sample} -> @*) {
                if ($syntax_tree -> content() =~ m/$token/xms) {
                    next;
                }

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

        return @results;
    }

    sub _get_token_variable_name {
        my ($token) = @_;

        if (ref($token) eq 'PPI::Token::QuoteLike::Backtick') {
            my $token_content = $token -> content();
            if ($token_content =~ /[\$\@\%](\w+)/xms) {
                return $1;
            }
            return;
        }

        my $next_element = $token -> snext_sibling;

        return if !defined $next_element || !ref $next_element;

        my $next_content = $next_element -> content();

        if ($next_content =~ /[\$\@\%](\w+)/xms) {
            return $1;
        }

        return;
    }

    sub _run_taint_analysis {
        my ($syntax_tree, $variable_name, $use_dataflow, $file) = @_;

        return if !$use_dataflow || !$file;

        my $data_flow_analyzer = Zarn::Network::DataFlowAnalyzer -> new([
            '--ast'  => $syntax_tree,
            '--file' => $file
        ]);

        $data_flow_analyzer -> {build_data_flow_graph} -> ();

        my $symbol_token = $syntax_tree -> find_first(
            sub {
                $_[1] -> isa('PPI::Token::Symbol') and
                ($_[1] -> content eq "\$$variable_name")
            }
        );

        return if !$symbol_token;

        my $location = $symbol_token -> location();
        my $line = $location -> [0];

        return $data_flow_analyzer -> {is_tainted} -> ($variable_name, $line);
    }

    sub new {
        my ($self, $parameters) = @_;
        my ($syntax_tree, $rules, $use_dataflow, $file, @results);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s'       => \$syntax_tree,
            'rules=s'     => \$rules,
            'dataflow=s'  => \$use_dataflow,
            'file=s'      => \$file
        );

        if (!$syntax_tree || !$rules) {
            return 0;
        }

        push @results, _process_absence_rules($syntax_tree, $rules);

        my @presence = grep { !($_ -> {type}) || $_ -> {type} eq 'presence' } $rules -> @*;

        foreach my $token (@{$syntax_tree -> find('PPI::Token') || []}) {
            foreach my $rule (@presence) {
                my @sample = $rule -> {sample} -> @*;

                next if !any { $token -> content() =~ m/$_/xms } @sample;

                my $variable_name = _get_token_variable_name($token);

                next if !defined $variable_name;

                my $taint_analysis = _run_taint_analysis($syntax_tree, $variable_name, $use_dataflow, $file);

                next if !$taint_analysis;

                my ($line_sink, $rowchar_sink)     = @{$token -> location};
                my ($line_source, $rowchar_source) = @{$taint_analysis};

                push @results, {
                    category       => $rule -> {category},
                    title          => $rule -> {name},
                    message        => $rule -> {message},
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
