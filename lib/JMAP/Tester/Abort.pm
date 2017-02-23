package JMAP::Tester::Abort;

use Moo;
extends 'Throwable::Error';

use namespace::clean;

use Sub::Exporter -setup => {
  exports => {
    abort => sub {
      my $pkg = shift;
      return sub { die $pkg->new(@_) }
    }
  }
};

around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;
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

sub as_test_abort_events {
  return [
    [ Ok => (pass => 0, name => $_[0]->message) ],
    ($_[0]->diagnostics
      ? (map {; [ Diag => (message => $_) ] } @{ $_[0]->diagnostics })
      : ()),
  ];
}

1;
