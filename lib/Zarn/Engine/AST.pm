package Zarn::Engine::AST {
    use strict;
    use warnings;
    use PPI::Find;
    use Getopt::Long;
    use PPI::Document;

    our $VERSION = '0.0.7';

    sub new {
        my ($self, $parameters) = @_;
        my ($file);

        Getopt::Long::GetOptionsFromArray (
            $parameters,
            'file=s'  => \$file
        );

        if ($file) {
            my $document = PPI::Document -> new($file);

            $document -> prune('PPI::Token::Pod');
            $document -> prune('PPI::Token::Comment');

            return $document;
        }

        return 0;
    }
}

1;