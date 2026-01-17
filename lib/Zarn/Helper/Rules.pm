package Zarn::Helper::Rules {
    use strict;
    use warnings;
    use Zarn::Component::Utils::Rules ();

    our $VERSION = '0.0.1';

    sub new {
        my ($class, @args) = @_;

        return Zarn::Component::Utils::Rules -> new(@args);
    }
}

1;
