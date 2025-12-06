package Zarn::Helper::Files {
    use strict;
    use warnings;
    use File::Find::Rule;

    our $VERSION = '0.0.4';

    sub new {
        my ($self, $source, $ignore) = @_;

        if ($source) {
            my $rule = File::Find::Rule -> new();
            my $exclude_rule = $rule -> new();

            $exclude_rule = $exclude_rule -> directory();
            $exclude_rule = $exclude_rule -> name('.git', $ignore);
            $exclude_rule = $exclude_rule -> prune();
            $exclude_rule = $exclude_rule -> discard();

            my $file_rule = $rule -> new();
            $rule -> or ($exclude_rule, $file_rule);

            $rule -> file -> nonempty();
            $rule -> name('*.pm', '*.t', '*.pl');

            my @files = $rule -> in($source);

            if (!@files) {
                print "[!] Could not identify any files in: $source.\n";

                return 1;
            }

            return @files;
        }

        return 0;
    }
}

1;