use v5.10.0;
package JMAP::Tester::CallResponse;
use Moo;

sub BUILDARGS {
  my ($self, $args) = @_;
  if (ref $args && ref $args eq 'ARRAY') {
    return {
      name => $args->[0],
      arguments => $args->[1],
      client_id => $args->[2],
    };
  }
  return $self->SUPER::BUILDARGS($args);
}

has name      => (is => 'ro', required => 1);
has arguments => (is => 'ro', required => 1);
has client_id => (is => 'ro', required => 1);

sub as_set {
  require JMAP::Tester::CallResponse::SetFoos;
  return JMAP::Tester::CallResponse::SetFoos->new({
    name      => $_[0]->name,
    arguments => $_[0]->arguments,
    client_id => $_[0]->client_id,
  });
}

1;
