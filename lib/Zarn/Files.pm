package Zarn::Files {
    use strict;
    use warnings;
    use File::Find::Rule;

    sub new {
        my ($self, $source, $ignore) = @_;

        # Check if source directory is provided
        unless ($source) {
            warn "Source directory not provided";
            return 0; # REVIEW o 0 é para retornar sucesso?
        }

        my $rule = File::Find::Rule->new();

        $rule->or(
            $rule->new->directory->name(".git", $ignore)->prune->discard,
            $rule->new
        );

        $rule->file->nonempty;
        $rule->name("*.pm", "*.t", "*.pl");

        my @files = $rule->in($source);

        return @files;
    }
}

1;