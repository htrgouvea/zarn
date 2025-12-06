package Zarn::Engine::Source_to_Sink {
    use strict;
    use warnings;
    use PPI::Find;
    use Getopt::Long;
    use List::Util 'any';
    use PPI::Document;
    use Zarn::Engine::Taint_Analysis;

    our $VERSION = '0.0.4';

    sub new {
        my ($self, $parameters) = @_;
        my ($ast, $rules, @results);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s'   => \$ast,
            'rules=s' => \$rules
        );

        return 0 unless ($ast && $rules);

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

                next unless any { my $content = $_; scalar(any { $content =~ m/$_/xms } @sample) } $token -> content();

                my $next_element = $token -> snext_sibling;
                next unless (defined $next_element && ref $next_element);

                my $variable_name = $next_element -> content() =~ /[\$\@\%](\w+)/xms ? $1 : undef;
                next unless $variable_name;

                my $taint_analysis = Zarn::Engine::Taint_Analysis -> new ([
                    '--ast'   => $ast,
                    '--token' => $variable_name
                ]);

                next unless $taint_analysis;

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