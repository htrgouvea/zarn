package main;

use strict;
use warnings;

our $VERSION = '0.01';
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use File::Basename;
use File::Find;
use File::Slurp;
use Zarn::Helper::Files;

my $temp_dir = tempdir(CLEANUP => 1);

my @dirs = (
    File::Spec -> catdir($temp_dir, 'dir1'),
    File::Spec -> catdir($temp_dir, 'dir2', '.git'),
);

my @files = (
    File::Spec -> catfile($temp_dir, 'dir1', 'file1.pm'),
    File::Spec -> catfile($temp_dir, 'dir1', 'file2.t'),
    File::Spec -> catfile($temp_dir, 'dir1', 'file3.pl'),
    File::Spec -> catfile($temp_dir, 'dir2', 'file4.pm'),
    File::Spec -> catfile($temp_dir, 'dir2', 'file5.txt'),
    File::Spec -> catfile($temp_dir, 'dir2', '.git', 'file6.pm'),
);

foreach my $dir (@dirs) {
    make_path($dir);
}

foreach my $file (@files) {
    write_file($file, "use strict;\n");
}

my @expected_files = (
    File::Spec -> catfile($temp_dir, 'dir1', 'file1.pm'),
    File::Spec -> catfile($temp_dir, 'dir1', 'file2.t'),
    File::Spec -> catfile($temp_dir, 'dir1', 'file3.pl'),
    File::Spec -> catfile($temp_dir, 'dir2', 'file4.pm'),
);

my @found_files = Zarn::Helper::Files -> new($temp_dir, '.git');
@found_files = sort @found_files;
@expected_files = sort @expected_files;

is_deeply(\@found_files, \@expected_files, 'Perl files correctly found in the source directory');

my $no_source = Zarn::Helper::Files -> new();
is($no_source, 0, 'Returns 0 when no source directory is provided');

done_testing();
1;
