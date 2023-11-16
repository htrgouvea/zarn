package Zarn::AST {
    use strict;
    use warnings;
    use Getopt::Long;
    use PPI::Find;
    use PPI::Document;
    use Zarn::Sarif;
    use JSON;

    sub new {
        my ($class, $parameters) = @_;
        my ($file, $rules, $sarif);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            "file=s"  => \$file,
            "rules=s" => \$rules,
            "sarif=s" => \$sarif
        );

        my $self = {
            file     => $file,
            rules    => $rules,
            sarif    => $sarif,
            document => undef,
            sarif_report => undef
        };

        bless $self, $class;

        if ($file && $rules) {
            $self -> {document} = PPI::Document->new($file);
            $self -> {document} -> prune("PPI::Token::Pod");
            $self -> {document} -> prune("PPI::Token::Comment");

            $self->{sarif_report} = Zarn::Sarif->new() if $sarif;

            foreach my $token (@{$self -> {document}->find("PPI::Token")}) {
                foreach my $rule (@{$self -> {rules}}) {
                    my @sample   = $rule -> {sample}->@*;
                    my $category = $rule -> {category};
                    my $title    = $rule -> {name};

                    if ($self -> matches_sample($token -> content(), \@sample)) {
                        $self -> process_sample_match($category, $title, $token);
                    }
                }
            }
        }

        return 1;
    }

    sub matches_sample {
        my ($self, $content, $sample) = @_;

        return grep {
            my $sample_content = $_;
            scalar(grep {$content =~ m/$_/} @$sample)
        } @$sample;
    }

    sub process_sample_match {
        my ($self, $category, $title, $token) = @_;

        my $next_element = $token->snext_sibling;

        # this is a draft source-to-sink function
        if (defined $next_element && ref $next_element && $next_element->content() =~ /[\$\@\%](\w+)/) {
            # perform taint analysis
            $self->perform_taint_analysis($category, $title, $next_element);
        }
    }

    sub perform_taint_analysis {
        my ($self, $category, $title, $next_element) = @_;

        my $var_token = $self -> {document} -> find_first(
            sub { $_[1] -> isa("PPI::Token::Symbol") and $_[1]->content eq "\$$1" }
        );

        if ($var_token && $var_token -> can("parent")) {
            if (($var_token -> parent -> isa("PPI::Token::Operator") || $var_token -> parent -> isa("PPI::Statement::Expression"))) {
                my ($line, $rowchar) = @{ $var_token -> location };

                if ($self -> {sarif}) {
                    $self -> {sarif_report} -> add_vulnerability(0, $title, $self -> {file}, $line);
                    print encode_json($self -> {sarif_report} -> prepare_for_json());
                } else {
                    print "[$category] - FILE:" . $self -> {file} . "\t Potential: $title. \t Line: $line:$rowchar.\n";
                }
            }
        }
    }
}

1;
