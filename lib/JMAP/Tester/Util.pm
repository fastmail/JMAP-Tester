use v5.14.0;
use warnings;
package JMAP::Tester::Util;

use Carp ();
use Params::Util qw( _ARRAY0 _HASH0 );

sub resolve_modified_jpointer {
  my ($jpointer, $struct) = @_;

  return (undef, "no pointer given") unless defined $jpointer;
  return (undef, "pointer begins with non-slash") if $jpointer =~ m{\A[^/]};

  # Drop the leading empty bit.  Don't drop trailing empty bits.
  my (undef, @tokens) = split m{/}, $jpointer, -1;

  s{~1}{/}g, s{~0}{~}g for @tokens;

  my ($result, $error) = _descend_modified_jpointer(\@tokens, $struct);
  return $result unless wantarray;
  return ($result, $error);
}

sub _descend_modified_jpointer {
  my ($token_queue, $struct, $pos) = @_;
  $pos //= '';

  my $error;

  TOKEN: while (defined(my $token = shift @$token_queue)) {
    $pos .= "/$token";

    if (_ARRAY0($struct)) {
      if ($token eq '*') {
        my @map;
        for my $i (0 .. $#$struct) {
          my ($i_result, $i_error) = _descend_modified_jpointer(
            [@$token_queue],
            $struct->[$i],
            $pos,
          );

          if ($i_error) {
            $error = "$i_error with asterisk indexing $i";
            last TOKEN;
          }

          push @map, _ARRAY0($i_result) ? @$i_result : $i_result;
        }

        $struct = \@map;
        last TOKEN;
      }

      if ($token eq '-') {
        # Special notice that this will never work in JMAP, even though it's
        # valid JSON Pointer. -- rjbs, 2018-01-10
        $error = qq{"-" not allowed as array index in JMAP at $pos};
        last TOKEN;
      }

      if ($token eq '0' or $token =~ /\A[1-9][0-9]*\z/) {
        if ($token > $#$struct) {
          $error = qq{index out of bounds at $pos};
          last TOKEN;
        }

        $struct = $struct->[$token];
        next TOKEN;
      }
    }

    if (_HASH0($struct)) {
      unless (exists $struct->{$token}) {
        $error = qq{property does not exist at $pos};
        last TOKEN;
      }

      $struct = $struct->{$token};
      next TOKEN;
    }

    $error = qq{can't descend into non-Array, non-Object at $pos};
    last TOKEN;
  }

  return (undef, $error) if $error;
  return ($struct, undef);
}

1;
