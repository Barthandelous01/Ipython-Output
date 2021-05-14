#!/usr/bin/perl
# get-output.pl
# Author: Barthandelous01
use utf8;
use strict;
use warnings;
use open qw(:std :utf8);
use File::Basename;

# Get the arg count
my $ARGC = @ARGV;

# If we don't get at least one, we exit with usage
if ($ARGC < 1) {
    print("Usage: $0 [notebook]\n");
    exit(1);
}

# the input ipython notebook we were given
my $infile = $ARGV[0];

system("sbcl --quit --disable-debugger --eval '(ql:quickload :cl-json)' --load './get-output.lisp' --eval '(main \"$infile\")' --eval '(quit)'");

# Parse the necessary chunks of the filename
my ($name, $path, $ext) = fileparse($infile, qr/\.[^.]*/);

# use pandoc to convert to docx
system("pandoc --to docx \"$name.org\" -o \"$name.docx\"");
unlink("$name.org");
