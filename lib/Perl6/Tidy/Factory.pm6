=begin pod

=begin NAME

Perl6::Tidy::Factory - Builds client-ready Perl 6 data tree

=end NAME

=begin DESCRIPTION

Generates the complete tree of Perl6-ready objects, shielding the client from the ugly details of the internal L<nqp> representation of the object. None of the elements, hash values or children should have L<NQPMatch> objects associated with them, as trying to view them can cause nasty crashes.

The child classes are described below, and have what's hopefully a reasonable hierarchy of entries. The root is a L<Perl6::Element>, and everything genrated by the factory is a subclass of that.

Read on for a breadth-first survey of the objects, but below is a brief summary.

L<Perl6::Element>
    L<...>
    L<...>
    L<Perl6::Number>
        L<Perl6::Number::Binary>
        L<Perl6::Number::Decimal>
        L<Perl6::Number::Octal>
        L<Perl6::Number::Hexadecimal>
        L<Perl6::Number::Radix>
    L<Perl6::Variable>
	    L<Perl6::Variable::Scalar>
	        L<Perl6::Variable::Scalar::Dynamic>
                L<...>
	    L<Perl6::Variable::Hash>
	    L<Perl6::Variable::Array>
	    L<Perl6::Variable::Callable>
	    L<Perl6::Variable::Contextualizer>
	        L<Perl6::Variable::Contextualizer::Scalar>
	            L<Perl6::Variable::Contextualizer::Scalar::Dynamic>

=end DESCRIPTION

=begin CLASSES

=item L<Perl6::Element>

The root of the object hierarchy.

This hierarchy is mostly for the clients' convenience, so that they can safely ignore the fact that an object is actually a L<Perl6::Number::Complex::Radix::Floating> when all they really want to know is that it's a L<Perl6::Number>.

It'll eventually have a bunch of useful methods attached to it, but for the moment ... well, it doesn't actually exist.

=cut

=item L<Perl6::Number>

All numbers, whether decimal, rational, radix-32 or complex, fall under this class. You should be able to compare C<$x> to L<Perl6::Number> to do a quick check. Under this lies the teeming complexity of the full Perl 6 numeric lattice.

Binary, octal, hex and radix numbers have an additional C<$.headless> attribute, which gives you the binary value without the leading C<0b>. Radix numbers (C<:13(19a)>) have an additional C<$.radix> attribute specifying the radix, and its C<$.headless> attribute works as you'd expect, delivering C<'19a'> without the surrounding C<':13(..)'>.

Imaginary numbers have an alternative C<$.tailless> attribute which gives you the decimal value without the trailing C<i> marker.

Rather than spelling out a huge list, here's how the hierarchy looks:

L<Perl6::Number>
    L<Perl6::Number::Binary>
    L<Perl6::Number::Octal>
    L<Perl6::Number::Decimal>
        L<Perl6::Number::Decimal::Floating>
    L<Perl6::Number::Hexadecimal>
    L<Perl6::Number::Radix>
    L<Perl6::Number::Imaginary>

There likely won't be a L<Perl6::Number::Complex>. While it's relatively easy to figure out that C<my $z = 3+2i;> is a complex number, who's to say what the intet behind C<my $z = 3*$a+2i> is, or a more complex high-order polynomial. Best to just assert that C<2i> is an imaginary number, and leave it to the client to form the proper interpretation.

=cut

=item L<Perl6::Variable>

The catch-all for Perl 6 variable types.

Scalar, Hash, Array and Callable subtypes have C<$.headless> attributes with the variable's name minus the sigil and optional twigil. They also all have C<$.sigil> which keeps the sigil C<$> etc., and C<$.twigil> optionally for the classes that have twigils.

L<Perl6::Variable>
    L<Perl6::Variable::Scalar>
        L<Perl6::Variable::Scalar::Dynamic>
        L<Perl6::Variable::Scalar::Attribute>
        L<Perl6::Variable::Scalar::CompileTimeVariable>
        L<Perl6::Variable::Scalar::MatchIndex>
        L<Perl6::Variable::Scalar::Positional>
        L<Perl6::Variable::Scalar::Named>
        L<Perl6::Variable::Scalar::Pod>
        L<Perl6::Variable::Scalar::Sublanguage>
    L<Perl6::Variable::Hash>
        (and the same subtypes)
    L<Perl6::Variable::Array>
        (and the same subtypes)
    L<Perl6::Variable::Callable>
        (and the same subtypes)

=cut

=item L<Perl6::Variable::Contextualizer>

Children: L<Perl6::Variable::Contextualizer::Scalar> and so forth.

(a side note - These really should be L<Perl6::Variable::Scalar:Contextualizer::>, but that would mean that these were both a Leaf (from the parent L<Perl6::Variable::Scalar> and a Branch (because they have children). Resolving this would mean removing the L<Perl6::Leaf> role from the L<Perl6::Variable::Scalar> class, which means that I either have to create a longer class name for L<Perl6::Variable::JustAPlainScalarVariable> or manually add the L<Perl6::Leaf>'s contents to the L<Perl6::Variable::Scalar>, and forget to update it when I change my mind in a few weeks' time about what L<Perl6::Leaf> does. Adding a separate class for this seems the lesser of two evils, especially given how often they'll appear in "real world" code.)

=cut

=end CLASSES

=begin ROLES

=item L<Perl6::Node>

Purely a virtual role. Client-facing classes use this to require the C<Str()> functionality of the rest of the classes in the system.

=cut

=item Perl6::Leaf

Represents things such as numbers that are a token unto themselves.

Classes such as C<Perl6::Number> and C<Perl6::Quote> mix in this role in order to declare that they represent stand-alone tokens. Any class that uses this can expect a C<$.content> member to contain the full text of the token, whether it be a variable such as C<$a> or a 50-line heredoc string.

Classes can have custom attributes such as a number's radix value, or a string's delimiters, but they'll always have a C<$.content> value.

=cut

=item Perl6::Branch

Represents things such as lists and circumfix operators that have children.

Anything that's not a C<Perl6::Leaf> wil have this role mixed in, and provide a C<@.child> accessor to get at, say, elements in a list or the expressions in a standalone subroutine.

Child elements aren't restricted to leaves, because a document is a tree the C<@.child> elements can be anything, even including the class itself. Although not the object itself, to avoid recursive loops.

=cut

=end ROLES

=end pod

# XXX Expect to see this a lot...
class Perl6::Unimplemented {
	has $.content is required
}

role Perl6::Node {
	method Str() {...}
}

# Documents will be laid out in a typical tree format.
# I'll use 'Leaf' to distinguish nodes that have no children from those that do.
#
role Perl6::Leaf does Perl6::Node {
	has $.content is required;
	method Str() { ~$.content }
}

role Perl6::Branch does Perl6::Node {
	has @.child;
}

# In passing, please note that Factory methods don't have to validate their
# contents.

class Perl6::Document does Perl6::Branch {
	method Str() { '' }
}

class Perl6::ScopeDeclarator does Perl6::Leaf {
	has Str $.scope;
	method Str() { '' }
}

class Perl6::Scoped does Perl6::Leaf {
}

class Perl6::Declarator does Perl6::Leaf {
}

# * 	Dynamic
# ! 	Attribute (class member)
# ? 	Compile-time variable
# . 	Method (not really a variable)
# < 	Index into match object (not really a variable)
# ^ 	Self-declared formal positional parameter
# : 	Self-declared formal named parameter
# = 	Pod variables
# ~ 	The sublanguage seen by the parser at this lexical spot

# Variables themselves are neither Leaves nor Branches, because they could
# be contextualized, such as '$[1]'.
#
class Perl6::Variable {
	has Str $.headless;

	method Str() { ~$.content }
}

class Perl6::Variable::Contextualizer does Perl6::Branch {
	also is Perl6::Variable;

	method Str() { '' }
}

class Perl6::Variable::Contextualizer::Scalar {
	also is Perl6::Variable::Contextualizer;
	has $.sigil = '$';
}
class Perl6::Variable::Contextualizer::Hash {
	also is Perl6::Variable::Contextualizer;
	has $.sigil = '%';
}
class Perl6::Variable::Contextualizer::Array {
	also is Perl6::Variable::Contextualizer;
	has $.sigil = '@';
}
class Perl6::Variable::Contextualizer::Callable {
	also is Perl6::Variable::Contextualizer;
	has $.sigil = '&';
}

class Perl6::Variable::Scalar does Perl6::Leaf {
	also is Perl6::Variable;
	has $.sigil = '$';
}
class Perl6::Variable::Scalar::Dynamic {
	also is Perl6::Variable::Scalar;
	has $.twigil = '*';
}
class Perl6::Variable::Scalar::Attribute {
	also is Perl6::Variable::Scalar;
	has $.twigil = '!';
}
class Perl6::Variable::Scalar::CompileTimeVariable {
	also is Perl6::Variable::Scalar;
	has $.twigil = '?';
}
class Perl6::Variable::Scalar::MatchIndex {
	also is Perl6::Variable::Scalar;
	has $.twigil = '<';
}
class Perl6::Variable::Scalar::Positional {
	also is Perl6::Variable::Scalar;
	has $.twigil = '^';
}
class Perl6::Variable::Scalar::Named {
	also is Perl6::Variable::Scalar;
	has $.twigil = ':';
}
class Perl6::Variable::Scalar::Pod {
	also is Perl6::Variable::Scalar;
	has $.twigil = '~';
}
class Perl6::Variable::Scalar::Sublanguage {
	also is Perl6::Variable::Scalar;
	has $.twigil = '~';
}

class Perl6::Variable::Array does Perl6::Leaf {
	also is Perl6::Variable;
	has $.sigil = '@';
}
class Perl6::Variable::Array::Dynamic {
	also is Perl6::Variable::Array;
	has $.twigil = '*';
}
class Perl6::Variable::Array::Attribute {
	also is Perl6::Variable::Array;
	has $.twigil = '!';
}
class Perl6::Variable::Array::CompileTimeVariable {
	also is Perl6::Variable::Array;
	has $.twigil = '?';
}
class Perl6::Variable::Array::MatchIndex {
	also is Perl6::Variable::Array;
	has $.twigil = '<';
}
class Perl6::Variable::Array::Positional {
	also is Perl6::Variable::Array;
	has $.twigil = '^';
}
class Perl6::Variable::Array::Named {
	also is Perl6::Variable::Array;
	has $.twigil = ':';
}
class Perl6::Variable::Array::Pod {
	also is Perl6::Variable::Array;
	has $.twigil = '~';
}
class Perl6::Variable::Array::Sublanguage {
	also is Perl6::Variable::Array;
	has $.twigil = '~';
}

class Perl6::Variable::Hash does Perl6::Leaf {
	also is Perl6::Variable;
	has $.sigil = '%';
}
class Perl6::Variable::Hash::Dynamic {
	also is Perl6::Variable::Hash;
	has $.twigil = '*';
}
class Perl6::Variable::Hash::Attribute {
	also is Perl6::Variable::Hash;
	has $.twigil = '!';
}
class Perl6::Variable::Hash::CompileTimeVariable {
	also is Perl6::Variable::Hash;
	has $.twigil = '?';
}
class Perl6::Variable::Hash::MatchIndex {
	also is Perl6::Variable::Hash;
	has $.twigil = '<';
}
class Perl6::Variable::Hash::Positional {
	also is Perl6::Variable::Hash;
	has $.twigil = '^';
}
class Perl6::Variable::Hash::Named {
	also is Perl6::Variable::Hash;
	has $.twigil = ':';
}
class Perl6::Variable::Hash::Pod {
	also is Perl6::Variable::Hash;
	has $.twigil = '~';
}
class Perl6::Variable::Hash::Sublanguage {
	also is Perl6::Variable::Hash;
	has $.twigil = '~';
}

class Perl6::Variable::Callable does Perl6::Leaf {
	also is Perl6::Variable;
	has $.sigil = '&';
}
class Perl6::Variable::Callable::Dynamic {
	also is Perl6::Variable::Callable;
	has $.twigil = '*';
}
class Perl6::Variable::Callable::Attribute {
	also is Perl6::Variable::Callable;
	has $.twigil = '!';
}
class Perl6::Variable::Callable::CompileTimeVariable {
	also is Perl6::Variable::Callable;
	has $.twigil = '?';
}
class Perl6::Variable::Callable::MatchIndex {
	also is Perl6::Variable::Callable;
	has $.twigil = '<';
}
class Perl6::Variable::Callable::Positional {
	also is Perl6::Variable::Callable;
	has $.twigil = '^';
}
class Perl6::Variable::Callable::Named {
	also is Perl6::Variable::Callable;
	has $.twigil = ':';
}
class Perl6::Variable::Callable::Pod {
	also is Perl6::Variable::Callable;
	has $.twigil = '~';
}
class Perl6::Variable::Callable::Sublanguage {
	also is Perl6::Variable::Callable;
	has $.twigil = '~';
}

class Perl6::Tidy::Factory {

	sub dump( Mu $parsed ) {
		say $parsed.hash.keys.gist;
	}

	method trace( Str $term ) {
		note $term if $*TRACE;
	}

	method assert-Bool( Mu $parsed ) {
		return False if $parsed.hash;
		return False if $parsed.list;
		return False if $parsed.Int;
		return False if $parsed.Str;

		return True if $parsed.Bool;
		warn "Uncaught type";
		return False
	}

	# $parsed can only be Int, by extension Str, by extension Bool.
	#
	method assert-Int( Mu $parsed ) {
		return False if $parsed.hash;
		return False if $parsed.list;

		return True if $parsed.Int;
		return True if $parsed.Bool;
		warn "Uncaught type";
		return False
	}

	# $parsed can only be Num, by extension Int, by extension Str, by extension Bool.
	#
	method assert-Num( Mu $parsed ) {
		return False if $parsed.hash;
		return False if $parsed.list;

		return True if $parsed.Num;
		warn "Uncaught type";
		return False
	}

	# $parsed can only be Str, by extension Bool
	#
	method assert-Str( Mu $parsed ) {
		return False if $parsed.hash;
		return False if $parsed.list;
		return False if $parsed.Num;
		return False if $parsed.Int;

		return True if $parsed.Str;
		warn "Uncaught type";
		return False
	}

	method assert-hash-keys( Mu $parsed, $keys, $defined-keys = [] ) {
		return False unless $parsed and $parsed.hash;

		my @keys;
		my @defined-keys;
		for $parsed.hash.keys {
			if $parsed.hash.{$_} {
				@keys.push( $_ );
			}
			elsif $parsed.hash:defined{$_} {
				@defined-keys.push( $_ );
			}
		}

		if $parsed.hash.keys.elems !=
			$keys.elems + $defined-keys.elems {
#				warn "Test " ~
#					$keys.gist ~
#					", " ~
#					$defined-keys.gist ~
#					" against parser " ~
#					$parsed.hash.keys.gist;
#				CONTROL { when CX::Warn { warn .message ~ "\n" ~ .backtrace.Str } }
			return False
		}
		
		for @( $keys ) -> $key {
			next if $parsed.hash.{$key};
			return False
		}
		for @( $defined-keys ) -> $key {
			next if $parsed.hash:defined{$key};
			return False
		}
		return True
	}

	method _ArgList( Mu $parsed ) returns Bool {
		CATCH { when X::Hash::Store::OddNumber { .resume } }
		for $parsed.list {
			next if self.assert-hash-keys( $_, [< EXPR >] );
			next if self.assert-Bool( $_ );
		}
		return True if self.assert-hash-keys( $parsed,
				[< deftermnow initializer term_init >],
				[< trait >] );
		return True if self.assert-hash-keys( $parsed, [< EXPR >] );
		return True if self.assert-Int( $parsed );
		return True if self.assert-Bool( $parsed );
	}

	method _Args( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p,
				[< invocant semiarglist >] );
		return True if self.assert-hash-keys( $p, [< semiarglist >] );
		return True if self.assert-hash-keys( $p, [ ],
				[< semiarglist >] );
		return True if self.assert-hash-keys( $p, [< arglist >] );
		return True if self.assert-hash-keys( $p, [< EXPR >] );
		return True if self.assert-Bool( $p );
		return True if self.assert-Str( $p );
	}

	method _Assertion( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< var >] );
		return True if self.assert-hash-keys( $p, [< longname >] );
		return True if self.assert-hash-keys( $p, [< cclass_elem >] );
		return True if self.assert-hash-keys( $p, [< codeblock >] );
		return True if $p.Str;
	}

	method _Atom( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< metachar >] );
		return True if self.assert-Str( $p );
	}

	method _Babble( Mu $p ) returns Bool {
		# _B is a Bool leaf
		return True if self.assert-hash-keys( $p,
				[< B >], [< quotepair >] );
	}

	method _BackSlash( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< sym >] );
		return True if self.assert-Str( $p );
	}

	method _Block( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< blockoid >] );
	}

	method _Blockoid( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< statementlist >] );
	}

	method _Blorst( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< statement >] );
		return True if self.assert-hash-keys( $p, [< block >] );
	}

	method _Bracket( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< semilist >] );
	}

	method _CClassElem( Mu $p ) returns Bool {
		for $p.list {
			# _Sign is a Str/Bool leaf
			next if self.assert-hash-keys( $_,
					[< identifier name sign >],
					[< charspec >] );
			# _Sign is a Str/Bool leaf
			next if self.assert-hash-keys( $_,
					[< sign charspec >] );
		}
	}

	method _CharSpec( Mu $p ) returns Bool {
# XXX work on this, of course.
		return True if $p.list;
	}

	method _Circumfix( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< nibble >] );
		return True if self.assert-hash-keys( $p, [< pblock >] );
		return True if self.assert-hash-keys( $p, [< semilist >] );
		# _BinInt is a Str/Int leaf
		# _VALUE is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< binint VALUE >] );
		# _OctInt is a Str/Int leaf
		# _VALUE is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< octint VALUE >] );
		# _HexInt is Str/Int leaf
		# _VALUE is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< hexint VALUE >] );
	}

	method _CodeBlock( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< block >] );
	}

	method _Coercee( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< semilist >] );
	}

	method _ColonCircumfix( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p, [< circumfix >] );
	}

	method _ColonPair( Mu $p ) returns Bool {
		return True if self.assert-hash-keys( $p,
				     [< identifier coloncircumfix >] );
		return True if self.assert-hash-keys( $p, [< identifier >] );
		return True if self.assert-hash-keys( $p, [< fakesignature >] );
		return True if self.assert-hash-keys( $p, [< var >] );
	}

	method _ColonPairs( Mu $p ) {
		if $p ~~ Hash {
			return True if $p.<D>;
			return True if $p.<U>;
		}
	}

	method _Contextualizer( Mu $p ) {
		# _Sigil is a Str leaf
		return True if self.assert-hash-keys( $p,
				[< coercee circumfix sigil >] );
	}

	method _Declarator( Mu $p ) {
		if self.assert-hash-keys( $p,
				[< deftermnow initializer term_init >],
				[< trait >] ) {
Perl6::Unimplemented.new(:content( "_Declarator") );
		}
		elsif self.assert-hash-keys( $p,
				[< initializer signature >], [< trait >] ) {
Perl6::Unimplemented.new(:content( "_Declarator") );
		}
		elsif self.assert-hash-keys( $p,
				  [< initializer variable_declarator >],
				  [< trait >] ) {
Perl6::Unimplemented.new(:content( "_Declarator") );
		}
		elsif self.assert-hash-keys( $p,
				[< variable_declarator >], [< trait >] ) {
			self._VariableDeclarator(
				$p.hash.<variable_declarator>
			)
		}
		elsif self.assert-hash-keys( $p,
				[< regex_declarator >], [< trait >] ) {
Perl6::Unimplemented.new(:content( "_Declarator") );
		}
		elsif self.assert-hash-keys( $p,
				[< routine_declarator >], [< trait >] ) {
Perl6::Unimplemented.new(:content( "_Declarator") );
		}
		elsif self.assert-hash-keys( $p,
				[< signature >], [< trait >] ) {
Perl6::Unimplemented.new(:content( "_Declarator") );
		}
	}

	method _DECL( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< deftermnow initializer term_init >],
				[< trait >] );
		return True if self.assert-hash-keys( $p,
				[< deftermnow initializer signature >],
				[< trait >] );
		return True if self.assert-hash-keys( $p,
				[< initializer signature >], [< trait >] );
		return True if self.assert-hash-keys( $p,
					  [< initializer variable_declarator >],
					  [< trait >] );
		return True if self.assert-hash-keys( $p,
				[< signature >], [< trait >] );
		return True if self.assert-hash-keys( $p,
					  [< variable_declarator >],
					  [< trait >] );
		return True if self.assert-hash-keys( $p,
					  [< regex_declarator >],
					  [< trait >] );
		return True if self.assert-hash-keys( $p,
					  [< routine_declarator >],
					  [< trait >] );
		return True if self.assert-hash-keys( $p,
					  [< package_def sym >] );
		return True if self.assert-hash-keys( $p,
					  [< declarator >] );
	}

	method _DecNumber( Mu $p ) {
		# _Coeff is a Str/Int leaf
		# _Frac is a Str/Int leaf
		# _Int is a Str/Int leaf
		return True if self.assert-hash-keys( $p,
				  [< int coeff frac escale >] );
		# _Coeff is a Str/Int leaf
		# _Frac is a Str/Int leaf
		return True if self.assert-hash-keys( $p,
				  [< coeff frac escale >] );
		# _Coeff is a Str/Int leaf
		# _Frac is a Str/Int leaf
		# _Int is a Str/Int leaf
		return True if self.assert-hash-keys( $p,
				  [< int coeff frac >] );
		# _Coeff is a Str/Int leaf
		# _Int is a Str/Int leaf
		return True if self.assert-hash-keys( $p,
				  [< int coeff escale >] );
		# _Coeff is a Str/Int leaf
		# _Frac is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< coeff frac >] );
	}

	method _DefLongName( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< name >], [< colonpair >] );
	}

	method _DefTerm( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< identifier colonpair >] );
		return True if self.assert-hash-keys( $p,
				[< identifier >], [< colonpair >] );
	}

	method _DefTermNow( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< defterm >] );
	}

	method _DeSigilName( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< longname >] );
		return True if $p.Str;
	}

	method _Dig( Mu $p ) {
		for $p.list {
			# UTF-8....
			if $_ {
				# XXX
				next
			}
			else {
				next
			}
		}
	}

	method _Dotty( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym dottyop O >] );
	}

	method _DottyOp( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< sym postop >], [< O >] );
		return True if self.assert-hash-keys( $p, [< methodop >] );
		return True if self.assert-hash-keys( $p, [< colonpair >] );
	}

	method _DottyOpish( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< term >] );
	}

	method _E1( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< scope_declarator >] );
	}

	method _E2( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< infix OPER >] );
	}

	method _E3( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< postfix OPER >],
				[< postfix_prefix_meta_operator >] );
	}

	method _Else( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym blorst >] );
		return True if self.assert-hash-keys( $p, [< blockoid >] );
	}

	method _EScale( Mu $p ) {
		# _DecInt is a Str/Int leaf
		# _Sign is a Str/Bool leaf
		return True if self.assert-hash-keys( $p, [< sign decint >] );
	}

	method _EXPR( Mu $p ) {
		if $p.list {
			for $p.list {
				if self.assert-hash-keys( $_,
						[< dotty OPER >],
						[< postfix_prefix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
					[< postcircumfix OPER >],
					[< postfix_prefix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< infix OPER >],
						[< infix_postfix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< prefix OPER >],
						[< prefix_postfix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< postfix OPER >],
						[< postfix_prefix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< identifier args >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
					[< infix_prefix_meta_operator OPER >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< longname args >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< args op >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_, [< value >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< longname >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< variable >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< methodop >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< package_declarator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_, [< sym >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< scope_declarator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_, [< dotty >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< circumfix >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< fatarrow >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-hash-keys( $_,
						[< statement_prefix >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
				elsif self.assert-Str( $_ ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
				}
			}
			if self.assert-hash-keys(
					$p,
					[< fake_infix OPER colonpair >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
			}
			elsif self.assert-hash-keys(
					$p,
					[< OPER dotty >],
					[< postfix_prefix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
			}
			elsif self.assert-hash-keys(
					$p,
					[< postfix OPER >],
					[< postfix_prefix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
			}
			elsif self.assert-hash-keys(
					$p,
					[< infix OPER >],
					[< prefix_postfix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
			}
			elsif self.assert-hash-keys(
					$p,
					[< prefix OPER >],
					[< prefix_postfix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
			}
			elsif self.assert-hash-keys(
					$p,
					[< postcircumfix OPER >],
					[< postfix_prefix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
			}
			elsif self.assert-hash-keys( $p,
					[< OPER >],
					[< infix_prefix_meta_operator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
			}
		}
		# _Triangle is a Str leaf
		if self.assert-hash-keys( $p,
				[< args op triangle >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< longname args >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< identifier args >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< args op >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< sym args >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< statement_prefix >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< type_declarator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< longname >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< value >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< variable >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< circumfix >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< colonpair >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< scope_declarator >] ) {
			self._ScopeDeclarator( $p.hash.<scope_declarator> )
		}
		elsif self.assert-hash-keys( $p, [< routine_declarator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< package_declarator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< fatarrow >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< multi_declarator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< regex_declarator >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		elsif self.assert-hash-keys( $p, [< dotty >] ) {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
		else {
Perl6::Unimplemented.new(:content( "_EXPR") );
		}
	}

	method _FakeInfix( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< O >] );
	}

	method _FakeSignature( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< signature >] );
	}

	method _FatArrow( Mu $p ) {
		# _Key is a Str leaf
		return True if self.assert-hash-keys( $p, [< val key >] );
	}

	method _Identifier( Mu $p ) {
		for $p.list {
			next if self.assert-Str( $_ );
		}
		return True if $p.Str;
	}

	method _Infix( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< EXPR O >] );
		return True if self.assert-hash-keys( $p, [< infix OPER >] );
		return True if self.assert-hash-keys( $p, [< sym O >] );
	}

	method _Infixish( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< infix OPER >] );
	}

	method _InfixPrefixMetaOperator( Mu $p ) {
		return True if self.assert-hash-keys( $p,
			[< sym infixish O >] );
	}

	method _Initializer( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym EXPR >] );
		return True if self.assert-hash-keys( $p,
			[< dottyopish sym >] );
	}

	method _Integer( Mu $p ) {
		# _DecInt is a Str/Int leaf
		# _VALUE is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< decint VALUE >] );
		# _BinInt is a Str/Int leaf
		# _VALUE is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< binint VALUE >] );
		# _OctInt is a Str/Int leaf
		# _VALUE is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< octint VALUE >] );
		# _HexInt is Str/Int leaf
		# _VALUE is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< hexint VALUE >] );
	}

	method _Invocant( Mu $p ) {
		CATCH {
			when X::Multi::NoMatch { }
		}
		#return True if $p ~~ QAST::Want;
		#return True if self.assert-hash-keys( $p, [< XXX >] );
# XXX Fixme
#say $p.dump;
#say $p.dump_annotations;
#say "############## " ~$p.<annotations>.gist;#<BY>;
return True;
	}

	method _Left( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< termseq >] );
	}

	method _LongName( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< name >],
				[< colonpair >] );
	}

	method _MetaChar( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym >] );
		return True if self.assert-hash-keys( $p, [< codeblock >] );
		return True if self.assert-hash-keys( $p, [< backslash >] );
		return True if self.assert-hash-keys( $p, [< assertion >] );
		return True if self.assert-hash-keys( $p, [< nibble >] );
		return True if self.assert-hash-keys( $p, [< quote >] );
		return True if self.assert-hash-keys( $p, [< nibbler >] );
		return True if self.assert-hash-keys( $p, [< statement >] );
	}

	method _MethodDef( Mu $p ) {
		# _Specials is a Bool leaf
		return True if self.assert-hash-keys( $p,
			     [< specials longname blockoid multisig >],
			     [< trait >] );
		# _Specials is a Bool leaf
		return True if self.assert-hash-keys( $p,
			     [< specials longname blockoid >],
			     [< trait >] );
	}

	method _MethodOp( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< longname args >] );
		return True if self.assert-hash-keys( $p, [< longname >] );
		return True if self.assert-hash-keys( $p, [< variable >] );
	}

	method _Min( Mu $p ) {
		# _DecInt is a Str/Int leaf
		# _VALUE is a Str/Int leaf
		return True if self.assert-hash-keys( $p, [< decint VALUE >] );
	}

	method _ModifierExpr( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< EXPR >] );
	}

	method _ModuleName( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< longname >] );
	}

	method _MoreName( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_, [< identifier >] );
		}
	}

	method _MultiDeclarator( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< sym routine_def >] );
		return True if self.assert-hash-keys( $p,
				[< sym declarator >] );
		return True if self.assert-hash-keys( $p, [< declarator >] );
	}

	method _MultiSig( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< signature >] );
	}

	method _NamedParam( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< param_var >] );
	}

	method _Name( Mu $p ) {
		# _Quant is a Bool leaf
		return True if self.assert-hash-keys( $p,
			[< param_var type_constraint quant >],
			[< default_value modifier trait post_constraint >] );
		return True if self.assert-hash-keys( $p,
			[< identifier >], [< morename >] );
		return True if self.assert-hash-keys( $p, [< subshortname >] );
		return True if self.assert-hash-keys( $p, [< morename >] );
		return True if self.assert-Str( $p );
	}

	method _Nibble( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< termseq >] );
		return True if $p.Str;
		return True if $p.Bool;
	}

	method _Nibbler( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< termseq >] );
	}

	method _Noun( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_,
				[< sigmaybe sigfinal quantifier atom >] );
			next if self.assert-hash-keys( $_,
				[< sigfinal quantifier separator atom >] );
			next if self.assert-hash-keys( $_,
				[< sigmaybe sigfinal separator atom >] );
			next if self.assert-hash-keys( $_,
				[< atom sigfinal quantifier >] );
			next if self.assert-hash-keys( $_,
				[< atom >], [< sigfinal >] );
		}
	}

	method _Number( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< numish >] );
	}

	method _Numish( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< integer >] );
		return True if self.assert-hash-keys( $p, [< rad_number >] );
		return True if self.assert-hash-keys( $p, [< dec_number >] );
		return True if self.assert-Num( $p );
	}

	method _O( Mu $p ) {
		CATCH {
			when X::Multi::NoMatch { .resume }
			#default { .resume }
			default { }
		}
		return True if $p.<thunky>
			and $p.<prec>
			and $p.<fiddly>
			and $p.<reducecheck>
			and $p.<pasttype>
			and $p.<dba>
			and $p.<assoc>;
		return True if $p.<thunky>
			and $p.<prec>
			and $p.<pasttype>
			and $p.<dba>
			and $p.<iffy>
			and $p.<assoc>;
		return True if $p.<prec>
			and $p.<pasttype>
			and $p.<dba>
			and $p.<diffy>
			and $p.<iffy>
			and $p.<assoc>;
		return True if $p.<prec>
			and $p.<fiddly>
			and $p.<sub>
			and $p.<dba>
			and $p.<assoc>;
		return True if $p.<prec>
			and $p.<nextterm>
			and $p.<fiddly>
			and $p.<dba>
			and $p.<assoc>;
		return True if $p.<thunky>
			and $p.<prec>
			and $p.<dba>
			and $p.<assoc>;
		return True if $p.<prec>
			and $p.<diffy>
			and $p.<dba>
			and $p.<assoc>;
		return True if $p.<prec>
			and $p.<iffy>
			and $p.<dba>
			and $p.<assoc>;
		return True if $p.<prec>
			and $p.<fiddly>
			and $p.<dba>
			and $p.<assoc>;
		return True if $p.<prec>
			and $p.<dba>
			and $p.<assoc>;
	}

	method _Op( Mu $p ) {
		return True if self.assert-hash-keys( $p,
			     [< infix_prefix_meta_operator OPER >] );
		return True if self.assert-hash-keys( $p, [< infix OPER >] );
	}

	method _OPER( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym dottyop O >] );
		return True if self.assert-hash-keys( $p,
				[< sym infixish O >] );
		return True if self.assert-hash-keys( $p, [< sym O >] );
		return True if self.assert-hash-keys( $p, [< EXPR O >] );
		return True if self.assert-hash-keys( $p,
				[< semilist O >] );
		return True if self.assert-hash-keys( $p, [< nibble O >] );
		return True if self.assert-hash-keys( $p, [< arglist O >] );
		return True if self.assert-hash-keys( $p, [< dig O >] );;
		return True if self.assert-hash-keys( $p, [< O >] );
	}

	method _PackageDeclarator( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< sym package_def >] );
	}

	method _PackageDef( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< blockoid longname >], [< trait >] );
		return True if self.assert-hash-keys( $p,
				[< longname statementlist >], [< trait >] );
		return True if self.assert-hash-keys( $p,
				[< blockoid >], [< trait >] );
	}

	method _Parameter( Mu $p ) {
		for $p.list {
			# _Quant is a Bool leaf
			next if self.assert-hash-keys( $_,
				[< param_var type_constraint quant >],
				[< default_value modifier trait
				   post_constraint >] );
			# _Quant is a Bool leaf
			next if self.assert-hash-keys( $_,
				[< param_var quant >],
				[< default_value modifier trait
				   type_constraint
				   post_constraint >] );

			# _Quant is a Bool leaf
			next if self.assert-hash-keys( $_,
				[< named_param quant >],
				[< default_value modifier
				   post_constraint trait
				   type_constraint >] );
			# _Quant is a Bool leaf
			next if self.assert-hash-keys( $_,
				[< defterm quant >],
				[< default_value modifier
				   post_constraint trait
				   type_constraint >] );
			next if self.assert-hash-keys( $_,
				[< type_constraint >],
				[< param_var quant default_value						   modifier post_constraint trait
				   type_constraint >] );
		}
	}

	method _ParamVar( Mu $p ) {
		# _Sigil is a Str leaf
		return True if self.assert-hash-keys( $p,
				[< name twigil sigil >] );
		# _Sigil is a Str leaf
		return True if self.assert-hash-keys( $p, [< name sigil >] );
		return True if self.assert-hash-keys( $p, [< signature >] );
		# _Sigil is a Str leaf
		return True if self.assert-hash-keys( $p, [< sigil >] );
	}

	method _PBlock( Mu $p ) {
		# _Lambda is a Str leaf
		return True if self.assert-hash-keys( $p,
				     [< lambda blockoid signature >] );
		return True if self.assert-hash-keys( $p, [< blockoid >] );
	}

	method _PostCircumfix( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< nibble O >] );
		return True if self.assert-hash-keys( $p, [< semilist O >] );
		return True if self.assert-hash-keys( $p, [< arglist O >] );
	}

	method _Postfix( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< dig O >] );
		return True if self.assert-hash-keys( $p, [< sym O >] );
	}

	method _PostOp( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< sym postcircumfix O >] );
		return True if self.assert-hash-keys( $p,
				[< sym postcircumfix >], [< O >] );
	}

	method _Prefix( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym O >] );
	}

	method _QuantifiedAtom( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sigfinal atom >] );
	}

	method _Quantifier( Mu $p ) {
		# _Max is a Str leaf
		# _BackMod is a Bool leaf
		return True if self.assert-hash-keys( $p,
				[< sym min max backmod >] );
		# _BackMod is a Bool leaf
		return True if self.assert-hash-keys( $p, [< sym backmod >] );
	}

	method _Quibble( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< babble nibble >] );
	}

	method _Quote( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< sym quibble rx_adverbs >] );
		return True if self.assert-hash-keys( $p,
				[< sym rx_adverbs sibble >] );
		return True if self.assert-hash-keys( $p, [< nibble >] );
		return True if self.assert-hash-keys( $p, [< quibble >] );
	}

	method _QuotePair( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_, [< identifier >] );
		}
		# _Radix is a Str/Int leaf
		return True if self.assert-hash-keys( $p,
				[< circumfix bracket radix >], [< exp base >] );
		return True if self.assert-hash-keys( $p, [< identifier >] );
	}

	method _RadNumber( Mu $p ) {
		# _Radix is a Str/Int leaf
		return True if self.assert-hash-keys( $p,
				[< circumfix bracket radix >], [< exp base >] );
		# _Radix is a Str/Int leaf
		return True if self.assert-hash-keys( $p,
				[< circumfix radix >], [< exp base >] );
	}

	method _RegexDeclarator( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym regex_def >] );
	}

	method _RegexDef( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< deflongname nibble >],
				[< signature trait >] );
	}

	method build( Mu $p ) {
		my $statementlist = $p.hash.<statementlist>;
		my $statement     = $statementlist.hash.<statement>;
		my @child;

		for $statement.list {
			@child.push(
				self._Statement( $_ )
			)
		}
		Perl6::Document.new(
			:child( @child )
		)
	}

	method _RoutineDeclarator( Mu $p ) {
		return True if self.assert-hash-keys( $p,
			[< sym method_def >] );
		return True if self.assert-hash-keys( $p,
				[< sym routine_def >] );
	}

	method _RoutineDef( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< blockoid deflongname multisig >],
				[< trait >] );
		return True if self.assert-hash-keys( $p,
				[< blockoid deflongname >],
				[< trait >] );
		return True if self.assert-hash-keys( $p,
				[< blockoid multisig >],
				[< trait >] );
		return True if self.assert-hash-keys( $p,
				[< blockoid >], [< trait >] );
	}

	method _RxAdverbs( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< quotepair >] );
		return True if self.assert-hash-keys( $p, [], [< quotepair >] );
	}

	method _Scoped( Mu $p ) {
		# XXX DECL seems to be a mirror of declarator. This probably
		# XXX will turn out to be not true later on.
		#
		if self.assert-hash-keys( $p,
				[< declarator DECL >], [< typename >] ) {
			Perl6::Scoped.new(
				:content(
					self._Declarator( $p.hash.<declarator> )
				)
			)
		}
		elsif self.assert-hash-keys( $p,
					[< multi_declarator DECL typename >] ) {
Perl6::Unimplemented.new(:content( "_Scoped") );
		}
		elsif self.assert-hash-keys( $p,
				[< package_declarator DECL >],
				[< typename >] ) {
Perl6::Unimplemented.new(:content( "_Scoped") );
		}
	}

	method _ScopeDeclarator( Mu $p ) {
		Perl6::ScopeDeclarator.new(
			:content( self._Scoped( $p.hash.<scoped> ) ),
			:scope( $p.hash.<sym>.Str ),
		)
	}

	method _SemiArgList( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< arglist >] );
	}

	method _SemiList( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_, [< statement >] );
		}
		return True if self.assert-hash-keys( $p, [ ],
			[< statement >] );
	}

	method _Separator( Mu $p ) {
		# _SepType is a Str leaf
		return True if self.assert-hash-keys( $p,
				[< septype quantified_atom >] );
	}

	method _Sibble( Mu $p ) {
		# _Right is a Bool leaf
		return True if self.assert-hash-keys( $p,
				[< right babble left >] );
	}

	method _SigFinal( Mu $p ) {
		# _NormSpace is a Str leaf
		return True if self.assert-hash-keys( $p, [< normspace >] );
	}

	method _SigMaybe( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< parameter typename >],
				[< param_sep >] );
		return True if self.assert-hash-keys( $p, [],
				[< param_sep parameter >] );
	}

	method _Signature( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< parameter typename >],
				[< param_sep >] );
		return True if self.assert-hash-keys( $p,
				[< parameter >],
				[< param_sep >] );
		return True if self.assert-hash-keys( $p, [],
				[< param_sep parameter >] );
	}

	method _SMExpr( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< EXPR >] );
	}

	method _StatementControl( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< block sym e1 e2 e3 >] );
		# _Wu is a Str leaf
		return True if self.assert-hash-keys( $p,
				[< pblock sym EXPR wu >] );
		# _Doc is a Bool leaf
		return True if self.assert-hash-keys( $p,
				[< doc sym module_name >] );
		# _Doc is a Bool leaf
		return True if self.assert-hash-keys( $p,
				[< doc sym version >] );
		return True if self.assert-hash-keys( $p,
				[< sym else xblock >] );
		# _Wu is a Str leaf
		return True if self.assert-hash-keys( $p, [< xblock sym wu >] );
		return True if self.assert-hash-keys( $p, [< sym xblock >] );
		return True if self.assert-hash-keys( $p, [< block sym >] );
	}

	method _Statement( Mu $p ) {
		# N.B. we don't care so much *if* there's a list as *what's*
		# in the list. In other words we can assume that the content
		# is what we consider valid, so we can relax our requirements.
		for $p.list {
			if self.assert-hash-keys( $_,
					[< statement_mod_loop EXPR >] ) {
Perl6::Unimplemented.new(:content( "_Statement") );
			}
			elsif self.assert-hash-keys( $_,
					[< statement_mod_cond EXPR >] ) {
Perl6::Unimplemented.new(:content( "_Statement") );
			}
			elsif self.assert-hash-keys( $_, [< EXPR >] ) {
Perl6::Unimplemented.new(:content( "_Statement") );
			}
			elsif self.assert-hash-keys( $_,
					[< statement_control >] ) {
Perl6::Unimplemented.new(:content( "_Statement") );
			}
			elsif self.assert-hash-keys( $_, [],
					[< statement_control >] ) {
Perl6::Unimplemented.new(:content( "_Statement") );
			}
		}
		if self.assert-hash-keys( $p, [< statement_control >] ) {
Perl6::Unimplemented.new(:content( "_Statement") );
		}
		elsif self.assert-hash-keys( $p, [< EXPR >] ) {
			self._EXPR( $p.hash.<EXPR> )
		}
		else {
Perl6::Unimplemented.new(:content( "_Statement") );
		}
	}

	method _StatementList( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< statement >] );
		return True if self.assert-hash-keys( $p, [], [< statement >] );
	}

	method _StatementModCond( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< sym modifier_expr >] );
	}

	method _StatementModLoop( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym smexpr >] )
	}

	method _StatementPrefix( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym blorst >] );
	}

	method _SubShortName( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< desigilname >] );
	}

	method _Sym( Mu $p ) {
		for $p.list {
			next if $_.Str;
		}
		return True if $p.Bool and $p.Str eq '+';
		return True if $p.Bool and $p.Str eq '';
		return True if self.assert-Str( $p );
	}

	method _Term( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< methodop >] );
	}

	method _TermAlt( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_, [< termconj >] );
		}
	}

	method _TermAltSeq( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< termconjseq >] );
	}

	method _TermConj( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_, [< termish >] );
		}
	}

	method _TermConjSeq( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_, [< termalt >] );
		}
		return True if self.assert-hash-keys( $p, [< termalt >] );
	}

	method _TermInit( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym EXPR >] );
	}

	method _Termish( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_, [< noun >] );
		}
		return True if self.assert-hash-keys( $p, [< noun >] );
	}

	method _TermSeq( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< termaltseq >] );
	}

	method _Twigil( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< sym >] );
	}

	method _TypeConstraint( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_, [< typename >] );
			next if self.assert-hash-keys( $_, [< value >] );
		}
		return True if self.assert-hash-keys( $p, [< value >] );
		return True if self.assert-hash-keys( $p, [< typename >] );
	}

	method _TypeDeclarator( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< sym initializer variable >], [< trait >] );
		return True if self.assert-hash-keys( $p,
				[< sym initializer defterm >], [< trait >] );
		return True if self.assert-hash-keys( $p,
				[< sym initializer >] );
	}

	method _TypeName( Mu $p ) {
		for $p.list {
			next if self.assert-hash-keys( $_,
					[< longname colonpairs >],
					[< colonpair >] );
			next if self.assert-hash-keys( $_,
					[< longname >],
					[< colonpair >] );
		}
		return True if self.assert-hash-keys( $p,
				[< longname >], [< colonpair >] );
	}

	method _Val( Mu $p ) {
		return True if self.assert-hash-keys( $p,
				[< prefix OPER >],
				[< prefix_postfix_meta_operator >] );
		return True if self.assert-hash-keys( $p, [< value >] );
	}

	method _Value( Mu $p ) {
		return True if self.assert-hash-keys( $p, [< number >] );
		return True if self.assert-hash-keys( $p, [< quote >] );
	}

	method _Var( Mu $p ) {
		# _Sigil is a Str leaf
		return True if self.assert-hash-keys( $p,
				[< sigil desigilname >] );
		return True if self.assert-hash-keys( $p, [< variable >] );
	}

	method _VariableDeclarator( Mu $p ) {
		# _Shape is a Str leaf
		if self.assert-hash-keys( $p,
				[< semilist variable shape >],
				[< postcircumfix signature trait
				   post_constraint >] ) {
Perl6::Unimplemented.new(:content( "_VariableDeclarator") );
		}
		elsif self.assert-hash-keys( $p,
				[< variable >],
				[< semilist postcircumfix signature
				   trait post_constraint >] ) {
			self._Variable( $p.hash.<variable> );
		}
	}

	method _Variable( Mu $p ) {

		if self.assert-hash-keys( $p, [< contextualizer >] ) {
#die $p.dump;
			return;
		}

		my $sigil       = $p.hash.<sigil>.Str;
		my $twigil      = $p.hash.<twigil> ??
			          $p.hash.<twigil>.Str !! '';
		my $desigilname = $p.hash.<desigilname> ??
				  $p.hash.<desigilname>.Str !! '';
		my $content     = $p.hash.<sigil> ~ $twigil ~ $desigilname;
		my %lookup = (
			'$' => Perl6::Variable::Scalar,
			'$*' => Perl6::Variable::Scalar::Dynamic,
			'$!' => Perl6::Variable::Scalar::Attribute,
			'$?' => Perl6::Variable::Scalar::CompileTimeVariable,
			'$<' => Perl6::Variable::Scalar::MatchIndex,
			'$^' => Perl6::Variable::Scalar::Positional,
			'$:' => Perl6::Variable::Scalar::Named,
			'$=' => Perl6::Variable::Scalar::Pod,
			'$~' => Perl6::Variable::Scalar::Sublanguage,
			'%' => Perl6::Variable::Hash,
			'%*' => Perl6::Variable::Hash::Dynamic,
			'%!' => Perl6::Variable::Hash::Attribute,
			'%?' => Perl6::Variable::Hash::CompileTimeVariable,
			'%<' => Perl6::Variable::Hash::MatchIndex,
			'%^' => Perl6::Variable::Hash::Positional,
			'%:' => Perl6::Variable::Hash::Named,
			'%=' => Perl6::Variable::Hash::Pod,
			'%~' => Perl6::Variable::Hash::Sublanguage,
			'@' => Perl6::Variable::Array,
			'@*' => Perl6::Variable::Array::Dynamic,
			'@!' => Perl6::Variable::Array::Attribute,
			'@?' => Perl6::Variable::Array::CompileTimeVariable,
			'@<' => Perl6::Variable::Array::MatchIndex,
			'@^' => Perl6::Variable::Array::Positional,
			'@:' => Perl6::Variable::Array::Named,
			'@=' => Perl6::Variable::Array::Pod,
			'@~' => Perl6::Variable::Array::Sublanguage,
			'&' => Perl6::Variable::Callable,
			'&*' => Perl6::Variable::Callable::Dynamic,
			'&!' => Perl6::Variable::Callable::Attribute,
			'&?' => Perl6::Variable::Callable::CompileTimeVariable,
			'&<' => Perl6::Variable::Callable::MatchIndex,
			'&^' => Perl6::Variable::Callable::Positional,
			'&:' => Perl6::Variable::Callable::Named,
			'&=' => Perl6::Variable::Callable::Pod,
			'&~' => Perl6::Variable::Callable::Sublanguage,
		);

		my $leaf;
		$leaf = %lookup{$sigil ~ $twigil}.new(
			:content( $content ),
			:headless( $desigilname )
		);
#say $leaf.perl;
		return $leaf;

	}

	method _Version( Mu $p ) {
		# _VStr is an Int leaf
		return True if self.assert-hash-keys( $p, [< vnum vstr >] );
	}

	method _VNum( Mu $p ) {
		for $p.list {
			next if self.assert-Int( $_ );
		}
	}

	method _XBlock( Mu $p ) returns Bool {
		for $p.list {
			next if self.assert-hash-keys( $_, [< pblock EXPR >] );
		}
		return True if self.assert-hash-keys( $p, [< pblock EXPR >] );
		return True if self.assert-hash-keys( $p, [< blockoid >] );
	}

}
