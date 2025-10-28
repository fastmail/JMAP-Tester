package JMAP::Tester::Sugar;

use v5.20.0;
use warnings;

use experimental 'signatures';

use Sub::Exporter -setup => [ qw( jset jcreate ) ];

sub jset ($type, $arg, $call_id = undef) {
  my %method_arg = %$arg;
  if (my $create_spec = delete $method_arg{create}) {
    unless (ref $create_spec eq 'ARRAY') {
      $create_spec = [ $create_spec ];
    }

    $method_arg{create} = {};

    my $i = 0;
    for my $creation (@$create_spec) {
      $method_arg{create}{$i++} = $creation;
    }
  }

  return [
    "$type/set",
    \%method_arg,
    (defined $call_id ? $call_id : ()),
  ];
}

sub jcreate ($type, $create) {
  return jset($type, { create => $create });
}

1;
