package Zarn::Helper::Files {
    use strict;
    use warnings;
    use Zarn::Component::Utils::Files ();

    our $VERSION = '0.0.1';

    sub new {
        my ($class, @args) = @_;

        return Zarn::Component::Utils::Files -> new(@args);
    }
}

1;
