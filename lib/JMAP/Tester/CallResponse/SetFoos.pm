use v5.10.0;
package JMAP::Tester::CallResponse::SetFoos;
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

sub new_state { $_[0]->arguments->{newState} }
sub old_state { $_[0]->arguments->{oldState} }

sub created { $_[0]->arguments->{created} }

sub created_id {
  my ($self, $creation_id) = @_;
  return unless my $props = $self->created->{$creation_id};
  return $props->{id};
}

sub created_ids {
  map {; $_->{id} } values %{ $_[0]->created }
}

sub updated_ids   { @{ $_[0]->{updated} } }
sub destroyed_ids { @{ $_[0]->{destroyed} } }

sub not_created_ids   { @{ $_[0]->{notCreated} }   }
sub not_destroyed_ids { @{ $_[0]->{notDestroyed} } }
sub not_updated_ids   { @{ $_[0]->{notUpdated} }   }

1;
