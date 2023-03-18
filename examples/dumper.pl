#!/usr/bin/env perl

use 5.018;
use strict;
use warnings;
use PPI::Document;
use PPI::Dumper;

# Load a document
my $Module = PPI::Document->new( '/Users/heitorgouvea/Documents/zarn/examples/hello-world.pl' );
 
# Create the dumper
my $Dumper = PPI::Dumper->new( $Module );
 
# Dump the document
$Dumper->print;