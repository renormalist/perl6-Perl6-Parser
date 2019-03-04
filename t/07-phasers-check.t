use v6;

use Test;
use Perl6::Parser;

use lib 't/lib';
use Utils;

# Make certain that BEGIN {}, CHECK {}, phasers don't halt compilation.
# Also check that 'my $x will begin { }', 'my $x will check { }' phasers
# don't halt compilation.
#

plan 2 * 2;

my $*CONSISTENCY-CHECK = True;
my $*FALL-THROUGH      = True;

for ( True, False ) -> $*PURE-PERL {
	ok round-trips( Q{BEGIN { die "HALT!" }} ), Q{BEGIN};
	ok round-trips( Q{CHECK { die "HALT!" }} ), Q{CHECK};
	# XXX Yes, there is Q{my $x will begin { die "HALT!" }} as well.
	# XXX The simple answer doesn't seem to work, I'll work on it later.
}

# 'null' does not exist

# vim: ft=perl6