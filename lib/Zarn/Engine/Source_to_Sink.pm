package Zarn::Engine::Source_to_Sink {
    use strict;
    use warnings;
    use PPI::Find;
    use Getopt::Long;
    use PPI::Document;
    use Zarn::Engine::Taint_Analysis;

    our $VERSION = '0.0.2';

    sub new {
        my ($self, $parameters) = @_;
        my ($ast, $rules, @results);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            "ast=s"   => \$ast,
            "rules=s" => \$rules
        );

        if ($ast && $rules) {
            foreach my $token (@{$ast -> find("PPI::Token")}) {
                foreach my $rule (@{$rules}) {
                    my @sample   = $rule -> {sample} -> @*;
                    my $category = $rule -> {category};
                    my $title    = $rule -> {name};
                    my $message  = $rule -> {message};

                    if (grep {my $content = $_; scalar(grep {$content =~ m/$_/xms} @sample)} $token -> content()) {
                        my $next_element = $token -> snext_sibling;

                        # this is a draft source-to-sink function
                        if (defined $next_element && ref $next_element && $next_element -> content() =~ /[\$\@\%](\w+)/xms) {
                            my $taint_analysis = Zarn::Engine::Taint_Analysis -> new ([
                                "--ast" => $ast,
                                "--token" => $1,
                            ]);

                            if ($taint_analysis) {
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
                    }
                }
            }

            return @results;
        }
        
        return 0;
    }
}

1;