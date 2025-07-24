requires 'JSON',                '4.10';
requires 'File::Find::Rule',    '0.35';
requires 'Getopt::Long',        '2.58';
requires 'YAML::Tiny',          '1.76';
requires 'PPI::Document',       '1.283';
requires 'List::Util',          '1.69';

on 'test' => sub {
    requires 'Test::More',      '1.302214';
    requires 'Test::Exception', '0.43';
    requires 'File::Temp',      '0.2311';
    requires 'File::Path',      '2.18';
    requires 'File::Spec',      '3.94';
    requires 'File::Basename',  '5.42.0';
    requires 'File::Find',      '5.42.0';
    requires 'File::Slurp',     '9999.32';
};