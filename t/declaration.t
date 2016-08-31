use v6;

use Test;
use Perl6::Tidy;

#`(
#`(

In passing, please note that while it's trivially possible to bum down the
tests, doing so makes it harder to insert 'say $parsed.dump' to view the
AST, and 'say $tree.perl' to view the generated Perl 6 structure.

)

plan 3;

my $pt = Perl6::Tidy.new;
#my $*TRACE = 1;
#my $*DEBUG = 1;

subtest {
	plan 3;

	subtest {
		plan 3;

		subtest {
			plan 2;

			my $parsed = $pt.parse-source( Q{my $a} );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), Q{my $a}, Q{formatted};
		}, Q{my $a};

		subtest {
			plan 2;

			my $parsed = $pt.parse-source( Q{our $a} );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), Q{our $a}, Q{formatted};
		}, Q{our $a};

		todo Q{'anon $a' not implemented yet, maybe not ever.};

		subtest {
			plan 2;

			my $parsed = $pt.parse-source( Q{state $a} );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), Q{state $a}, Q{formatted};
		}, Q{state $a};

		todo Q{'augment $a' not implemented yet, maybe not ever.};

		todo Q{'supersede $a' not implemented yet, maybe not ever.};
	}, Q{untyped};

	subtest {
		plan 3;

		subtest {
			plan 2;

			my $parsed = $pt.parse-source( Q{my Int $a} );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), Q{my Int $a}, Q{formatted};
		}, Q{regular};

		subtest {
			plan 2;

			my $parsed = $pt.parse-source( Q{my Int:D $a = 0} );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ),
				Q{my Int:D $a = 0},
				Q{formatted};
		}, Q{defined};

		subtest {
			plan 2;

			my $parsed = $pt.parse-source( Q{my Int:U $a} );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), Q{my Int:U $a}, Q{formatted};
		}, Q{undefined};
	}, Q{typed};

	subtest {
		plan 1;

		subtest {
			plan 2;

			my $parsed = $pt.parse-source( Q{my $a where 1} );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), Q{my $a where 1}, Q{formatted};
		}, Q{my $a where 1};
	}, Q{constrained};
}, Q{variable};

subtest {
	plan 2;

	subtest {
		plan 2;

		my $source = Q:to[_END_];
sub foo {}
_END_
		my $parsed = $pt.parse-source( $source );
		my $tree = $pt.build-tree( $parsed );
		ok $pt.validate( $parsed ), Q{valid};
		is $pt.format( $tree ), $source, Q{formatted};
	}, Q{sub foo {}};

	subtest {
		plan 2;

		my $source = Q:to[_END_];
sub foo returns Int {}
_END_
		my $parsed = $pt.parse-source( $source );
		my $tree = $pt.build-tree( $parsed );
		ok $pt.validate( $parsed ), Q{valid};
		is $pt.format( $tree ), $source, Q{formatted};
	}, Q{sub foo returns Int {}};
}, Q{subroutine};

subtest {
	plan 7;

	subtest {
		plan 2;

		subtest {
			plan 2;

			my $source = Q:to[_END_];
unit module foo;
_END_
			my $parsed = $pt.parse-source( $source );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), $source, Q{formatted};
		}, Q{unit module foo;};

		subtest {
			plan 2;

			my $source = Q:to[_END_];
module foo { }
_END_
			my $parsed = $pt.parse-source( $source );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), $source, Q{formatted};
		}, Q{module foo {}};
	}, q{module};

	subtest {
		plan 2;

		subtest {
			plan 2;

			my $source = Q:to[_END_];
unit class foo;
_END_
			my $parsed = $pt.parse-source( $source );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), $source, Q{formatted};
		}, Q{unit class foo;};

		subtest {
			plan 2;

			my $source = Q:to[_END_];
class foo { }
_END_
			my $parsed = $pt.parse-source( $source );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), $source, Q{formatted};
		}, Q{class foo {}};
	}, Q{class};

	subtest {
		plan 2;

		subtest {
			plan 2;

			my $source = Q:to[_END_];
unit role foo;
_END_
			my $parsed = $pt.parse-source( $source );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), $source, Q{formatted};
		}, Q{unit role foo;};

		subtest {
			plan 2;

			my $source = Q:to[_END_];
role foo { }
_END_
			my $parsed = $pt.parse-source( $source );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), $source, Q{formatted};
		}, Q{role foo {}};
	}, Q{role};

	subtest {
		plan 2;

		my $source = Q:to[_END_];
my regex foo { a }
_END_
		my $parsed = $pt.parse-source( $source );
		my $tree = $pt.build-tree( $parsed );
		ok $pt.validate( $parsed ), Q{valid};
		is $pt.format( $tree ), $source, Q{formatted};
	}, Q{my regex foo {a} (null regex not allowed)};

	subtest {
		plan 2;

		subtest {
			plan 2;

			my $source = Q:to[_END_];
unit grammar foo;
_END_
			my $parsed = $pt.parse-source( $source );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), $source, Q{formatted};
		}, Q{unit grammar foo;};

		subtest {
			plan 2;

			my $source = Q:to[_END_];
grammar foo { }
_END_
			my $parsed = $pt.parse-source( $source );
			my $tree = $pt.build-tree( $parsed );
			ok $pt.validate( $parsed ), Q{valid};
			is $pt.format( $tree ), $source, Q{formatted};
		}, Q{grammar foo {}};
	}, Q{grammar};

	subtest {
		plan 2;

		my $source = Q:to[_END_];
my token foo { a }
_END_
		my $parsed = $pt.parse-source( $source );
		my $tree = $pt.build-tree( $parsed );
		ok $pt.validate( $parsed ), Q{valid};
		is $pt.format( $tree ), $source, Q{formatted};
	}, Q{my token foo {a} (null regex not allowed, must give it content.)};

	subtest {
		plan 2;

		my $source = Q:to[_END_];
my rule foo { a }
_END_
		my $parsed = $pt.parse-source( $source );
		my $tree = $pt.build-tree( $parsed );
		ok $pt.validate( $parsed ), Q{valid};
		is $pt.format( $tree ), $source, Q{formatted};
	}, Q{my rule foo {a}};
}, Q{braced things};
)

# vim: ft=perl6
