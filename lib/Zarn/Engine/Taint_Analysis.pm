package Zarn::Engine::Taint_Analysis {
    use strict;
    use warnings;
    use PPI::Find;
    use Getopt::Long;
    use PPI::Document;
    use List::Util 'any';

    our $VERSION = '0.0.2';

    sub new {
        my ($self, $parameters) = @_;
        my ($ast, $token);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'ast=s'   => \$ast,
            'token=s' => \$token
        );

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
}

1;