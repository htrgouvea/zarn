package Zarn::Component::Engine::AliasAnalyzer {
    use strict;
    use warnings;
    use Getopt::Long;

    our $VERSION = '0.1.0';

    sub new {
        my ($self, $parameters) = @_;
        my ($syntax_tree, $def_use_analyzer);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s'              => \$syntax_tree,
            'def_use_analyzer=s' => \$def_use_analyzer
        );

        if ($syntax_tree && $def_use_analyzer) {
            my $analyzer = {
                ast              => $syntax_tree,
                def_use_analyzer => $def_use_analyzer,
                analyze => sub {
                    my $statements = $syntax_tree -> find('PPI::Statement') || [];

                    for my $statement (@{$statements}) {
                        my $cast = $statement -> find_first(sub {
                            $_[1] -> isa('PPI::Token::Cast') && $_[1] -> content() eq q{\\}
                        });

                        if (!$cast) {
                            next;
                        }

                        my $next_token = $cast -> snext_sibling();

                        if (!$next_token || !$next_token -> isa('PPI::Token::Symbol')) {
                            next;
                        }

                        my $aliased_var = $next_token -> content();

                        $aliased_var =~ s/\A[\$\@\%]//xms;

                        my $symbol = $statement -> find_first('PPI::Token::Symbol');

                        if (!$symbol) {
                            next;
                        }

                        my $alias_var = $symbol -> content();

                        $alias_var =~ s/\A[\$\@\%]//xms;
                        $def_use_analyzer -> {add_alias} -> ($aliased_var, $alias_var);
                    }

                    return;
                },
            };

            return $analyzer;
        }

        return 0;
    }
}

1;
