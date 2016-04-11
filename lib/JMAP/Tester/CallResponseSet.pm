use v5.10.0;
package JMAP::Tester::CallResponseSet;
use Moo;

has responses => (is => 'bare', reader => '_responses', required => 1);

sub responses { @{ $_[0]->_responses } }

sub single {
  my ($self, $name) = @_;

  my @responses = $self->responses;

  Carp::confess("more than one response in set, but ->single called")
    if @responses > 1;

  Carp::confess("single response not of expected name <$name>")
    if defined $name && $name ne $responses[0]->name;

  return $responses[0];
}

sub as_struct {
  [ map {; $_->as_struct } $_[0]->responses ]
}

1;
