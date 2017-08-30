#!perl

use Test::More;

use Cwd;

say STDERR "Running in ", cwd;

ok(1, "does nothing");

done_testing;