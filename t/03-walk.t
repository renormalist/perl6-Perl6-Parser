use v6;

use Test;
use Perl6::Parser;
use Perl6::Parser::Factory;

plan 11;

my $pt = Perl6::Parser.new;
my $ppf = Perl6::Parser::Factory.new;
my $*CONSISTENCY-CHECK = True;
my $*FALL-THROUGH = True;

sub make-decimal( Str $value ) {
	Perl6::Number::Decimal.new( :from(0), :to(2), :content($value) );
}
sub make-list {
	Perl6::Operator::Circumfix.new( :from(0), :to(1), :child( ) );
}

# 27
subtest {
	my $tree = make-decimal( '27' );
	$ppf.thread( $tree );

	is $tree.parent,
		$tree;
	ok $tree.is-root;

	is $tree.next,
		$tree;
	ok $tree.is-end;

	is $tree.previous,
		$tree;
	ok $tree.is-start;
}

# '()'
subtest {
	my $tree = make-list();
	$ppf.thread( $tree );

	is $tree.parent,
		$tree;
	ok $tree.is-root;

	is $tree.next,
		$tree;
	ok $tree.is-end;

	is $tree.previous,
		$tree;
	ok $tree.is-start;
}

# '(27)' (not really - '27' because there's no '(',')'
subtest {
	my $tree = Perl6::Operator::Circumfix.new(
		:from(0),
		:to(1),
		:child(
			make-decimal( '27' )
		)
	);
	$ppf.thread( $tree );

	is $tree.parent,
		$tree;
	is $tree.child[0].parent,
		$tree;
	ok $tree.is-root;

	is $tree.next,
		$tree.child[0];
	is $tree.child[0].next,
		$tree.child[0];
	ok $tree.child[0].is-end;

	is $tree.child[0].previous,
		$tree;
	is $tree.previous,
		$tree;
	ok $tree.is-start;
}

# '(27 64)' (not really - no '(',')' characters.
subtest {
	my $tree =
		Perl6::Operator::Circumfix.new(
			:from(0),
			:to(2),
			:child(
				make-decimal( '27' ),
				make-decimal( '64' )
			)
		);
	$ppf.thread( $tree );

	is $tree.parent,
		$tree;
	is $tree.child[0].parent,
		$tree;
	is $tree.child[1].parent,
		$tree;
	ok $tree.is-root;

	is $tree.next,
		$tree.child[0];
	is $tree.child[0].next,
		$tree.child[1];
	is $tree.child[1].next,
		$tree.child[1];
	ok $tree.child[1].is-end;

	is $tree.child[1].previous,
		$tree.child[0];
	is $tree.child[0].previous,
		$tree;
	is $tree.previous,
		$tree;
	ok $tree.is-start;
}

# '(27 64)' (not really - no '(',')' characters.
subtest {
	my $tree =
		Perl6::Operator::Circumfix.new(
			:from(0),
			:to(2),
			:child(
				make-decimal( '27' ),
				make-decimal( '64' )
			)
		);
	$ppf.thread( $tree );

	ok !$tree.is-leaf;

	my $int-node = $tree.next-leaf;
	ok $int-node ~~ Perl6::Number::Decimal;
}

# '(()b)' (not really - '(',')' are missing
subtest {
	my $tree =
		# $tree -> $tree.child[0]
		Perl6::Operator::Circumfix.new(
			:from(0),
			:to(2),
			:child(
				# $tree.child[0] -> $tree.child[1]
				Perl6::Operator::Circumfix.new(
					:from(0),
					:to(1),
					:child()
				),
				# $tree.child[1] -> Any
				make-decimal( '27' )
			)
		);
	$ppf.thread( $tree );

	is $tree.parent, $tree;
	is $tree.child[0].parent, $tree;
	is $tree.child[1].parent, $tree;
	ok $tree.is-root;

	is $tree.next, $tree.child[0];
	is $tree.child[0].next, $tree.child[1];
	is $tree.child[1].next, $tree.child[1];
	ok $tree.child[1].is-end;

	is $tree.child[1].previous, $tree.child[0];
	is $tree.child[0].previous, $tree;
	is $tree.previous, $tree;
	ok $tree.is-start;
}

# '((a)b)' - not really, '(',')' are missing.
subtest {
	my $tree = # $tree -> $tree.child[0]
		Perl6::Operator::Circumfix.new(
			:from(0),
			:to(2),
			:child(
				# $tree.child[0] -> $tree.child[0].child[0]
				Perl6::Operator::Circumfix.new(
					:from(0),
					:to(1),
					:child(
						# $tree.child[0].child[0]
						# -> $tree.child[1]
						make-decimal( '27' )
					)
				),
				# $tree.child[1] -> Any
				make-decimal( '64' )
			)
		);
	$ppf.thread( $tree );

	is $tree.parent, $tree;
	is $tree.child[0].parent, $tree;
	is $tree.child[0].child[0].parent, $tree.child[0];
	is $tree.child[1].parent, $tree;
	ok $tree.is-root;

	is $tree.next, $tree.child[0];
	is $tree.child[0].next, $tree.child[0].child[0];
	is $tree.child[0].child[0].next, $tree.child[1];
	is $tree.child[1].next, $tree.child[1];
	ok $tree.child[1].is-end;

	is $tree.child[1].previous, $tree.child[0].child[0];
	is $tree.child[0].child[0].previous, $tree.child[0];
	is $tree.child[0].previous, $tree;
	is $tree.previous, $tree;
	ok $tree.is-start;
}

subtest {
	my $source = Q{(1);2;1};
	my $tree = $pt.to-tree( $source );
	$ppf.thread( $tree );
	is $pt.to-string( $tree ), $source, Q{formatted};

	is $tree.parent, $tree;
	is $tree.child[0].parent, $tree;
	is $tree.child[0].child[0].parent, $tree.child[0];
	is $tree.child[0].child[0].child[0].parent, $tree.child[0].child[0];
	is $tree.child[0].child[0].child[1].parent, $tree.child[0].child[0];
	is $tree.child[0].child[0].child[2].parent, $tree.child[0].child[0];
	is $tree.child[0].child[1].parent, $tree.child[0];
	is $tree.child[1].parent, $tree;
	is $tree.child[1].child[0].parent, $tree.child[1];
	is $tree.child[1].child[1].parent, $tree.child[1];
	is $tree.child[2].parent, $tree;
	is $tree.child[2].child[0].parent, $tree.child[2];
	ok $tree.is-root;

	is $tree.next, $tree.child[0];
	is $tree.child[0].next, $tree.child[0].child[0];
	is $tree.child[0].child[0].next, $tree.child[0].child[0].child[0];
	is $tree.child[0].child[0].child[0].next,
		$tree.child[0].child[0].child[1];
	is $tree.child[0].child[0].child[1].next,
		$tree.child[0].child[0].child[2];
	is $tree.child[0].child[0].child[2].next, $tree.child[0].child[1];
	is $tree.child[0].child[1].next, $tree.child[1];
	is $tree.child[1].next, $tree.child[1].child[0];
	is $tree.child[1].child[0].next, $tree.child[1].child[1];
	is $tree.child[1].child[1].next, $tree.child[2];
	is $tree.child[2].next, $tree.child[2].child[0];
	is $tree.child[2].child[0].next, $tree.child[2].child[0];
	ok $tree.child[2].child[0].is-end;

	is $tree.child[2].child[0].previous, $tree.child[2];
	is $tree.child[2].previous, $tree.child[1].child[1];
	is $tree.child[1].child[1].previous, $tree.child[1].child[0];
	is $tree.child[1].child[0].previous, $tree.child[1];
	is $tree.child[1].previous, $tree.child[0].child[1];
	is $tree.child[0].child[1].previous, $tree.child[0].child[0].child[2];
	is $tree.child[0].child[0].child[2].previous,
		$tree.child[0].child[0].child[1];
	is $tree.child[0].child[0].child[1].previous,
		$tree.child[0].child[0].child[0];
	is $tree.child[0].child[0].child[0].previous, $tree.child[0].child[0];
	is $tree.child[0].child[0].previous, $tree.child[0];
	is $tree.child[0].previous, $tree;
	is $tree.previous, $tree;
	ok $tree.is-start;

	done-testing;
}, Q{leading, trailing ws};

subtest {
	my $source = Q{(1);2;1};
	my $ecruos = Q{1;2;)1(};
	my $tree = $pt.to-tree( $source );
	$ppf.thread( $tree );

	my $head = $tree;
	my $iterated = '';
	while $head {
		$iterated ~= $head.content if $head.is-leaf;
		last if $head.is-end;
		$head = $head.next;
	}
	is $iterated, $source, Q{iterated forward};

	my $detareti = '';
	while $head {
		$detareti ~= $head.content if $head.is-leaf;
		last if $head.is-start;
		$head = $head.previous;
	}
	is $detareti, $ecruos, Q{iterated backwards};

	done-testing;
}, Q{simple iteration};

subtest {
	my $source = Q{(3);2;1};
	my $ecruos = Q{1;2;(3)};
	my $tree = $pt.to-tree( $source );
	$ppf.thread( $tree );
	my $head = $ppf.flatten( $tree );

	ok $head.parent ~~ Perl6::Document;
	ok $head ~~ Perl6::Document; $head = $head.next;
	ok $head.parent ~~ Perl6::Document;
	ok $head ~~ Perl6::Statement; $head = $head.next;
	ok $head.parent ~~ Perl6::Statement;
	ok $head ~~ Perl6::Operator::Circumfix; $head = $head.next;
	ok $head.parent ~~ Perl6::Operator::Circumfix;
	ok $head ~~ Perl6::Balanced::Enter; $head = $head.next;
	ok $head.parent ~~ Perl6::Operator::Circumfix;
	ok $head ~~ Perl6::Number::Decimal; $head = $head.next;
	ok $head.parent ~~ Perl6::Operator::Circumfix;
	ok $head ~~ Perl6::Balanced::Exit; $head = $head.next;
	ok $head.parent ~~ Perl6::Statement;
	ok $head ~~ Perl6::Semicolon; $head = $head.next;
	ok $head.parent ~~ Perl6::Document;
	ok $head ~~ Perl6::Statement; $head = $head.next;
	ok $head.parent ~~ Perl6::Statement;
	ok $head ~~ Perl6::Number::Decimal; $head = $head.next;
	ok $head.parent ~~ Perl6::Statement;
	ok $head ~~ Perl6::Semicolon; $head = $head.next;
	ok $head.parent ~~ Perl6::Document;
	ok $head ~~ Perl6::Statement; $head = $head.next;
	ok $head.parent ~~ Perl6::Statement;
	ok $head ~~ Perl6::Number::Decimal; $head = $head.next;
	ok $head.is-end;

	done-testing;
}, Q{check flattened data};

subtest {
	my $source = Q{();2;1;};
	my $iter = $pt.iterator( $source );
	my $iterated = '';

	for Seq.new( $iter ) {
		$iterated ~= $_.content;
	}
	is $iterated, $source, Q{pull-one returns complete list};

	done-testing;
}, Q{default iterator pull-one};

#subtest {
#	my $source = Q{();2;1;};
#	my $iter = $pt.iterator( $source );
#	my $iterated = '';
#	my $target = (1..Inf).iterator;
#
#	my @element;
#
#	$iter.push-exactly( $target, 3 );
#	ok $target.[0] ~~ Perl6::Document;
#
#	done-testing;
#}, Q{iterator push-exactly};

# vim: ft=perl6
