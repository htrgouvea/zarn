package Zarn::AST {
    use strict;
    use warnings;
    use Getopt::Long;
    use PPI::Find;
    use PPI::Document;

    sub new {
        my ($self, $parameters) = @_;
        my ($file, $rules);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            "file=s"  => \$file,
            "rules=s" => \$rules
        );

        if ($file && $rules) {
            my $document = PPI::Document -> new($file);

            $document -> prune("PPI::Token::Pod");
            $document -> prune("PPI::Token::Comment");

            foreach my $token (@{$document -> find("PPI::Token")}) {                    
                foreach my $rule (@{$rules}) {
                    my @sample   = $rule -> {sample} -> @*;
                    my $category = $rule -> {category};
                    my $title    = $rule -> {name};

                    if ($self -> matches_sample($token -> content(), \@sample)) {
                        $self -> process_sample_match($document, $category, $file, $title, $token);
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
        my ($self, $document, $category, $file, $title, $token) = @_;

        my $next_element = $token -> snext_sibling;

        # this is a draft source-to-sink function
        if (defined $next_element && ref $next_element && $next_element -> content() =~ /[\$\@\%](\w+)/) {  
            # perform taint analysis
            $self -> perform_taint_analysis($document, $category, $file, $title, $next_element);
        }
    }

    sub perform_taint_analysis {
        my ($self, $document, $category, $file, $title, $next_element) = @_;

        my $var_token = $document -> find_first(
            sub { $_[1 ] -> isa("PPI::Token::Symbol") and $_[1] -> content eq "\$$1" }
        );

        if ($var_token && $var_token -> can("parent")) {
            if (($var_token -> parent -> isa("PPI::Token::Operator") || $var_token -> parent -> isa("PPI::Statement::Expression"))) {
                my ($line, $rowchar) = @{ $var_token -> location };
                print "[$category] - FILE:$file \t Potential: $title. \t Line: $line:$rowchar.\n";
            }
        }
    }
}

1;
