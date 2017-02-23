use v5.10.0;
package JMAP::Tester::Response::Sentence;
# ABSTRACT: a single triple within a JMAP response

use Moo;

use JMAP::Tester::Abort 'abort';

use namespace::clean;

=head1 OVERVIEW

These objects represent sentences in the JMAP response.  That is, if your
response is:

  [
    [ "messages", { ... }, "a" ],      # 1
    [ "smellUpdates", { ... }, "b" ],  # 2
    [ "smells",       { ... }, "b" ],  # 3
  ]

...then #1, #2, and #3 are each a single sentence.

The first item in the triple is accessed with the C<name> method.  The second
is accessed with the C<arguments> method.  The third, with the C<client_id>
method.

=cut

sub BUILDARGS {
  my ($self, $args) = @_;

  if (my $triple = delete $args->{triple}) {
    return {
      %$args,

      name      => $triple->[0],
      arguments => $triple->[1],
      client_id => $triple->[2],
    };
  }
  return $self->SUPER::BUILDARGS($args);
}

has name      => (is => 'ro', required => 1);
has arguments => (is => 'ro', required => 1);
has client_id => (is => 'ro', required => 1);

has _json_typist => (
  is => 'ro',
  handles => {
    _strip_json_types => 'strip_types',
  },
);

=method as_struct

=method as_stripped_struct

C<as_struct> returns the underlying JSON data of the sentence, which may include
objects used to convey type information for booleans, strings, and numbers.

For raw data, use C<as_stripped_struct>.

These return a three-element arrayref.

=cut

sub as_struct { [ $_[0]->name, $_[0]->arguments, $_[0]->client_id ] }

sub as_stripped_struct {
  $_[0]->_strip_json_types($_[0]->as_struct);
}

=method as_pair

=method as_stripped_pair

C<as_pair> returns the same thing as C<as_struct>, but without the
C<client_id>.  That means it returns a two-element arrayref.

C<as_stripped_pair> returns the same minus JSON type information.

=cut

sub as_pair { [ $_[0]->name, $_[0]->arguments ] }

sub as_stripped_pair {
  $_[0]->_strip_json_types($_[0]->as_pair);
}

=method as_set

This method returns a L<JMAP::Tester::Response::Sentence::Set> object for the
current sentence.  That's a specialized Sentence for C<setFoos>-style JMAP
method responses.

=cut

sub as_set {
  require JMAP::Tester::Response::Sentence::Set;
  return JMAP::Tester::Response::Sentence::Set->new({
    name         => $_[0]->name,
    arguments    => $_[0]->arguments,
    client_id    => $_[0]->client_id,
    _json_typist => $_[0]->_json_typist,
  });
}

=method assert_named

  $sentence->assert_named("theName")

This method aborts unless the sentence's name is the given name.  Otherwise, it
returns the sentence.

=cut

sub assert_named {
  my ($self, $name) = @_;

  Carp::confess("no name given") unless defined $name;

  return $self if $self->name eq $name;

  abort(
    sprintf qq{expected sentence named "%s" but got "%s"}, $name, $self->name
  );
}

1;
