use v5.14.0;
use warnings;
package JMAP::Tester::Util;

use Carp ();
use Params::Util qw( _ARRAY0 _HASH0 );

sub resolve_modified_jpointer {
  my ($jpointer, $struct) = @_;

  Carp::confess("no jpointer given") unless defined $jpointer;
  Carp::confess("illegal jpointer: begin with non-slash")
    if $jpointer =~ m{\A[^/]};

  # Drop the leading empty bit.  Don't drop trailing empty bits.
  my (undef, @tokens) = split m{/}, $jpointer, -1;

  s{~1}{/}g, s{~0}{~}g for @tokens;

  return _descend_modified_jpointer(\@tokens, $struct);
}

sub _descend_modified_jpointer {
  my ($token_queue, $struct) = @_;

  TOKEN: while (defined(my $token = shift @$token_queue)) {

    if (_ARRAY0($struct)) {
      if ($token eq '*') {
        my @map = map {; _ARRAY0($_) ? @$_ : $_ }
                  map {; _descend_modified_jpointer([@$token_queue], $_) }
                  @$struct;
        $struct = \@map;
        last TOKEN;
      }

      if ($token eq '-') {
        # Special notice that this will never work in JMAP, even though it's
        # valid JSON Pointer. -- rjbs, 2018-01-10
        Carp::confess('illegal backref: "-" not allowed as array index in JMAP');
      }

      if ($token eq '0' or $token =~ /\A[1-9][0-9]*\z/) {
        Carp::confess("illegal backref: index out of bounds")
          unless @$struct > $token;

        $struct = $struct->[$token];
        next TOKEN;
      }
    }

    if (_HASH0($struct)) {
      Carp::confess('illegal backref: property does not exist')
        unless exists $struct->{$token};

      $struct = $struct->{$token};
      next TOKEN;
    }

    Carp::confess("can't descend into non-Array, non-Object data");
  }

  return $struct;
}

1;
