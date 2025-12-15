use v5.20.0;
package JMAP::Tester::Abort;

use Moo;
extends 'Throwable::Error';

use experimental 'signatures';

use namespace::clean;

use Sub::Exporter -setup => {
  exports => {
    abort => sub {
      my $pkg = shift;
      return sub (@args) { die $pkg->new(@args) }
    }
  }
};

around BUILDARGS => sub ($orig, $self, @args) {
  return { message => $args[0] } if @args == 1 && ! ref $args[0];
  return $self->$orig(@args);
};

has message => (
  is => 'ro',
  required => 1,
);

has diagnostics => (
  is => 'ro',
);

sub as_test_abort_events ($self) {
  return [
    [ Ok => (pass => 0, name => $self->message) ],
    ($self->diagnostics
      ? (map {; [ Diag => (message => $_) ] } @{ $self->diagnostics })
      : ()),
  ];
}

1;
