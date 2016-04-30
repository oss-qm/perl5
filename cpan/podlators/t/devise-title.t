#!/usr/bin/perl
#
# Tests for the automatic determination of the manual page title if not
# specified via options to pod2man or the Pod::Man constructor.

use 5.006;
use strict;
use warnings;

use File::Spec;
use IO::File;
use Test::More tests => 3;

BEGIN {
    use_ok('Pod::Man');
}

# Create a parser and set it up with an input source.  There isn't a way to do
# this in Pod::Simple without actually parsing the document, so send the
# output to a string that we'll ignore.
my $path = File::Spec->catdir('t', 'data', 'basic.pod');
my $handle = IO::File->new($path, 'r');
my $parser = Pod::Man->new(errors => 'pod');
my $output;
$parser->output_string(\$output);
$parser->parse_file($handle);

# Check the results of devise_title for this.  We should get back STDIN, and
# we should have reported an error.
my ($name, $section) = $parser->devise_title;
is($name, 'STDIN', 'devise_title uses STDIN for file handle input');
ok($parser->errors_seen, '...and errors were seen');
