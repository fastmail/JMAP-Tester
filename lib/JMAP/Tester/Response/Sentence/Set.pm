use v5.10.0;
package JMAP::Tester::Response::Sentence::Set;
# ABSTRACT: the kind of sentence you get in reply to a setFoos call

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

sub created_creation_ids {
  keys %{ $_[0]->created }
}

sub created_ids {
  map {; $_->{id} } values %{ $_[0]->created }
}

sub updated_ids   { @{ $_[0]{arguments}{updated} } }
sub destroyed_ids { @{ $_[0]{arguments}{destroyed} } }

# Is this the best API to provide?  I dunno, maybe.  Usage will tell us whether
# it's right. -- rjbs, 2016-04-11
sub not_created_ids   { keys %{ $_[0]{arguments}{notCreated} }   }
sub not_destroyed_ids { keys %{ $_[0]{arguments}{notDestroyed} } }
sub not_updated_ids   { keys %{ $_[0]{arguments}{notUpdated} }   }

sub create_errors     { $_[0]{arguments}{notCreated}   }
sub destroy_errors    { $_[0]{arguments}{notDestroyed} }
sub update_errors     { $_[0]{arguments}{notUpdated}   }

1;
