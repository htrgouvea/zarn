package Zarn::AST {
    use strict;
    use warnings;
    use Getopt::Long;
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

                    if (grep {my $content = $_; scalar(grep {$content =~ m/$_/} @sample)} $token -> content()) {
                        my $next_element = $token -> snext_sibling;

                        # this is a draft source-to-sink function
                        if (defined $next_element && ref $next_element && $next_element -> content() =~ /\$/) {
                            # if (!tainted()) {} // perform taint analyis 
                            print "[$category] - FILE:$file \t Potefntial: $title.\n";                            
                        }
                    }
                }       
            }
        }
        
        return 1;
    }
}

1;