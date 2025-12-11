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
}

sub json_literal ($bytes) {
  return JMAP::Tester::JSONLiteral->new($bytes);
}

1;
