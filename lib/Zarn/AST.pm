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
                    my @sample   = $rule -> {sample} -> @*;
                    my $category = $rule -> {category};
                    my $title    = $rule -> {name};
                    my $message  = $rule -> {message};

                    if (grep {my $content = $_; scalar(grep {$content =~ m/$_/xms} @sample)} $token -> content()) {
                        my $next_element = $token -> snext_sibling;

                        # this is a draft source-to-sink function
                        if (defined $next_element && ref $next_element && $next_element -> content() =~ /[\$\@\%](\w+)/xms) {
                            # perform taint analyis
                            my $var_token = $document -> find_first (                                
                                sub { 
                                    $_[1] -> isa("PPI::Token::Symbol") and 
                                    ($_[1] ->content eq "\$$1" or $_[1] -> content eq "\@$1" or $_[1] -> content eq "\%$1")
                                }
                            );

                            if ($var_token && $var_token -> can("parent")) {
                                my @childrens = $var_token -> parent -> children;

                                if (grep { # verifyng if the variable is a fixed string or a number
                                    $_ -> isa("PPI::Token::Quote::Double") ||
                                    $_ -> isa("PPI::Token::Quote::Single") ||
                                    $_ -> isa("PPI::Token::Number")
                                } @childrens) {
                                    next;
                                }

                                if ((
                                    $var_token -> parent -> isa("PPI::Token::Operator") ||
                                    $var_token -> parent -> isa("PPI::Statement::Expression")
                                )) {
                                    my ($line_sink, $rowchar_sink) = @{$token -> location};
                                    my ($line_source, $rowchar_source) = @{$var_token -> location};

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