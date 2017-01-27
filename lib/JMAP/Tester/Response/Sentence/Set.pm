use v5.10.0;
package JMAP::Tester::Response::Sentence::Set;
# ABSTRACT: the kind of sentence you get in reply to a setFoos call

use Moo;

use Data::Dumper ();
use JMAP::Tester::Abort 'abort';

=head1 OVERVIEW

A "Set" sentence is a kind of L<Sentence|JMAP::Tester::Response::Sentence>
for representing C<foosSet> results.  It has convenience methods for getting
out the data returned in these kinds of sentences.

=cut

has name      => (is => 'ro', required => 1);
has arguments => (is => 'ro', required => 1);
has client_id => (is => 'ro', required => 1);

has _json_typist => (
  is => 'ro',
  handles => {
    _strip_json_types => 'strip_types',
  },
);

=method new_state

This returns the C<newState> in the result.

=method old_state

This returns the C<newState> in the result.

=cut

sub new_state { $_[0]->arguments->{newState} }
sub old_state { $_[0]->arguments->{oldState} }

=method created

This returns the hashref of data in the C<created> property.

=method created_id

  my $id = $set->created_id( $cr_id );

This returns the id given to the object created for the given creation id.  If
that creation id doesn't correspond to a created object, C<undef> is returned.

=method created_creation_ids

This returns the list of creation ids that were successfully created.  Note:
this returns I<creation ids>, not object ids.

=method created_ids

This returns the list of object ids that were successfully created.

=method not_created_ids

This returns the list of creation ids that were I<not> successfully created.

=method create_errors

This returns a hashref mapping creation ids to error properties.

=method updated_ids

This returns a list of object ids that were successfully updated.

=method not_updated_ids

This returns a list of object ids that were I<not> successfully updated.

=method update_errors

This returns a hashref mapping object ids to error properties.

=method destroyed_ids

This returns a list of object ids that were successfully destroyed.

=method not_destroyed_ids

This returns a list of object ids that were I<not> successfully destroyed.

=method destroy_errors

This returns a hashref mapping object ids to error properties.

=cut

sub created { $_[0]->arguments->{created} }

sub created_id {
  my ($self, $creation_id) = @_;
  return undef unless my $props = $self->created->{$creation_id};
  return $props->{id};
}

sub created_creation_ids {
  keys %{ $_[0]->created }
}

sub created_ids {
  map {; $_->{id} } values %{ $_[0]->created }
}

sub updated_ids   {
  my ($self) = @_;
  my $updated = $_[0]{arguments}{updated} // {};

  if (ref $updated eq 'ARRAY') {
    return @$updated;
  }

  return keys %$updated;
}

sub updated {
  my ($self) = @_;

  my $updated = $_[0]{arguments}{updated} // {};

  if (ref $updated eq 'ARRAY') {
    return { map {; $_ => undef } @$updated };
  }

  return $updated;
}

sub destroyed_ids { @{ $_[0]{arguments}{destroyed} } }

# Is this the best API to provide?  I dunno, maybe.  Usage will tell us whether
# it's right. -- rjbs, 2016-04-11
sub not_created_ids   { keys %{ $_[0]{arguments}{notCreated} }   }
sub not_updated_ids   { keys %{ $_[0]{arguments}{notUpdated} }   }
sub not_destroyed_ids { keys %{ $_[0]{arguments}{notDestroyed} } }

sub create_errors     { $_[0]{arguments}{notCreated}   // {} }
sub update_errors     { $_[0]{arguments}{notUpdated}   // {} }
sub destroy_errors    { $_[0]{arguments}{notDestroyed} // {} }

sub assert_no_errors {
  my ($self) = @_;

  my @errors;
  local $Data::Dumper::Terse = 1;

  if (keys %{ $self->create_errors }) {
    push @errors, "notCreated: " .  Data::Dumper::Dumper(
      $self->_strip_json_types( $self->create_errors )
    );
  }

  if (keys %{ $self->update_errors }) {
    push @errors, "notUpdated: " .  Data::Dumper::Dumper(
      $self->_strip_json_types( $self->update_errors )
    );
  }

  if (keys %{ $self->destroy_errors }) {
    push @errors, "notDestroyed: " .  Data::Dumper::Dumper(
      $self->_strip_json_types( $self->destroy_errors )
    );
  }

  return unless @errors;

  abort({
    message     => "errors found in " . $self->name . " sentence",
    diagnostics => \@errors,
  });
}

1;
