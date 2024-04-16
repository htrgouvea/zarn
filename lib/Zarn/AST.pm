package Zarn::AST {
    use strict;
    use warnings;
    use Getopt::Long;
    use PPI::Find;
    use PPI::Document;
    
    our $VERSION = '0.0.4';

    sub new {
        my ($self, $parameters) = @_;
        my ($file, $rules, @results);

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
                    #匹配规则各个字段
                    my @sample   = $rule -> {sample} -> @*;
                    my $category = $rule -> {category};
                    my $title    = $rule -> {name};
                    my $message  = $rule -> {message};

                    if (grep {my $content = $_; scalar(grep {$content =~ m/$_/xms} @sample)} $token -> content()) 
                    { 
                        my $next_element = $token -> snext_sibling;
                        my $threshold_location;
                        $threshold_location = $token->location->[0];
                        if (defined $next_element && ref $next_element && $next_element -> content() =~ /[\$\@\%](\w+)/xms) {
                            my $matching_nodes = $document->find( 
                            sub {   $_[1] -> isa("PPI::Token::Symbol") and 
                                    ($_[1] ->content eq "\$$1" or $_[1] -> content eq "\@$1" or $_[1] -> content eq "\%$1") 
                                }
                            );
                            my $pre_node;
                            #search lastest variable 
                            foreach my $node (@$matching_nodes) {
                                if($node && $node->location->[0] < $threshold_location)
                                {
                                    $pre_node = $node;
                                }
                                else
                                {
                                    last;
                                }
                            }
                            if ($pre_node && $pre_node -> can("parent")) 
                            {
                                my @childrens = $pre_node -> parent -> children; 
                                
                                #grep{code block} lists : for every object，apply for code block
                            
                                if (grep { # verifyng if the variable is a fixed string or a number
                                    $_ -> isa("PPI::Token::Quote::Double") ||
                                    $_ -> isa("PPI::Token::Quote::Single") ||
                                    $_ -> isa("PPI::Token::Number")
                                } @childrens) {
                                    next;
                                }
                                
                                if (($pre_node -> parent -> isa("PPI::Token::Operator") ||$pre_node -> parent -> isa("PPI::Statement::Expression"))) 
                                {
                                    my ($line_sink, $rowchar_sink) = @{$token -> location};
                                    my ($line_source, $rowchar_source) = @{$pre_node -> location};

                                    push @results, {
                                        category       => $category,
                                        file           => $file,
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
            }

            return @results;
        }

        return 0;
    }


}

1;