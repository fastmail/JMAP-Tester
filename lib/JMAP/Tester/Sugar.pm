package JMAP::Tester::Sugar;

use v5.20.0;
use warnings;

use experimental 'signatures';

use Sub::Exporter -setup => [ qw( jset jcreate json_literal ) ];

sub jset ($type, $arg, $call_id = undef) {
  my %method_arg = %$arg;
  if (my $create_spec = delete $method_arg{create}) {
    unless (ref $create_spec eq 'ARRAY') {
      $create_spec = [ $create_spec ];
    }

    $method_arg{create} = {};

    my $i = 0;
    for my $creation (@$create_spec) {
      $method_arg{create}{"$type-" . $i++} = $creation;
    }
  }

  return [
    "$type/set",
    \%method_arg,
    (defined $call_id ? $call_id : ()),
  ];
}

sub jcreate ($type, $create, $call_id = undef) {
  return jset($type, { create => $create }, $call_id);
}

package JMAP::Tester::JSONLiteral {
  sub new {
    my ($class, $bytes) = @_;

    bless { _bytes => $bytes }, $class;
  }

  sub bytes { return $_[0]{_bytes} }

  sub TO_JSON {
    # Some day, somebody is going to think that they can do this:
    # $tester->request([[ json_literal(...), {...} ]]);
    #
    # ...but they can't, because you can't supply the JSON encoder a hunk of
    # bytes to stick in the middle.  We can only decline to encode *at all*.
    # Because TO_JSON can't really die to abort JSON encoding, we just put some
    # obvious "you did it wrong" text into the output, and then we hope that
    # the user reads the logging! -- rjbs, 2025-12-11
    return "ERROR: a JMAP::Tester json_literal was passed to a JSON encoder"
  }
}

sub json_literal ($bytes) {
  return JMAP::Tester::JSONLiteral->new($bytes);
}

1;
