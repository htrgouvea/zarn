requires 'JSON',             '4.11';
requires 'File::Find::Rule', '0.35';
requires 'Getopt::Long',     '2.58';
requires 'YAML::Tiny',       '1.76';
requires 'PPI::Document',    '1.284';
requires 'List::Util',       '1.63';

on 'test' => sub {
      requires 'Test::More',      '1.302219';
      requires 'Test::Exception', '0.43';
      requires 'File::Temp',      '0.2312';
      requires 'File::Path',      '2.18';
      requires 'File::Spec',      '3.75';
      requires 'File::Slurp',     '9999.32';
};
