package Zarn::Engine::Taint_Analysis {
    use strict;
    use warnings;
    use PPI::Find;
    use Getopt::Long;
    use PPI::Document;
    use List::Util 'any';
    use Zarn::Engine::DataFlow;

    our $VERSION = '0.0.4';

    sub new {
        my ($self, $parameters) = @_;
        my ($ast, $token, $use_dataflow, $file);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s'         => \$ast,
            'token=s'       => \$token,
            'dataflow=s'    => \$use_dataflow,
            'file=s'        => \$file
        );

        # Use enhanced data flow analysis if requested
        if ($use_dataflow && $ast && $token) {
            return _analyze_with_dataflow($ast, $token, $file);
        }

        # Legacy analysis (backward compatible)
        if ($ast && $token) {
            my $var_token = $ast -> find_first (
                sub {
                    $_[1] -> isa('PPI::Token::Symbol') and
                    ($_[1] -> content eq "\$$token") # or $_[1] -> content eq "\@$1" or $_[1] -> content eq "\%$1"
                }
            );

            if ($var_token && $var_token -> can('parent')) {
                my @childrens = $var_token -> parent() -> children();

                # verifyng if the variable is a fixed string or a number
                if (any {
                    $_ -> isa('PPI::Token::Quote::Double') ||
                    $_ -> isa('PPI::Token::Quote::Single') ||
                    $_ -> isa('PPI::Token::Number')
                } @childrens) {
                    return 0;
                }

                if (($var_token -> parent -> isa('PPI::Token::Operator') || $var_token -> parent -> isa('PPI::Statement::Expression'))) {
                    return $var_token -> location;
                }
            }
        }

        return 0;
    }

    sub _analyze_with_dataflow {
        my ($ast, $token, $file) = @_;

        # Create data flow engine instance
        my $df_engine = Zarn::Engine::DataFlow->new(
            ast  => $ast,
            file => $file || 'unknown'
        );

        # Build the data flow graph
        $df_engine->build_data_flow_graph();

        # Find the token location
        my $var_token = $ast->find_first(
            sub {
                $_[1]->isa('PPI::Token::Symbol') and
                ($_[1]->content eq "\$$token")
            }
        );

        return 0 unless $var_token;

        my $location = $var_token->location();
        my $line = $location->[0];

        # Check if the variable is tainted at this location
        my $taint_source = $df_engine->is_tainted($token, $line);

        return $taint_source;
    }
}

1;