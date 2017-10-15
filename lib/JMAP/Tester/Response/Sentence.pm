use v5.10.0;
package JMAP::Tester::Response::Sentence;
# ABSTRACT: a single triple within a JMAP response

use Moo;

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

has name      => (is => 'ro', required => 1);
has arguments => (is => 'ro', required => 1);
has client_id => (is => 'ro', required => 1);

has _jmap_response_abort_callback       => (is => 'ro');
has _jmap_response_strip_types_callback => (is => 'ro');

sub _strip_json_types {
  my ($self, $whatever) = @_;
  $self->_jmap_response_strip_types_callback->($whatever);
}

=method as_struct

=method as_stripped_struct

C<as_struct> returns the underlying JSON data of the sentence, which may include
objects used to convey type information for booleans, strings, and numbers.

For raw data, use C<as_stripped_struct>.

These return a three-element arrayref.

=cut

sub as_struct { [ $_[0]->name, $_[0]->arguments, $_[0]->client_id ] }

sub as_stripped_struct {
  $_[0]->_jmap_response_strip_types_callback->($_[0]->as_struct);
}

=method as_pair

=method as_stripped_pair

C<as_pair> returns the same thing as C<as_struct>, but without the
C<client_id>.  That means it returns a two-element arrayref.

C<as_stripped_pair> returns the same minus JSON type information.

=cut

sub as_pair { [ $_[0]->name, $_[0]->arguments ] }

sub as_stripped_pair {
  $_[0]->_jmap_response_strip_types_callback->($_[0]->as_pair);
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

    _jmap_response_abort_callback       => $_[0]->_jmap_response_abort_callback,
    _jmap_response_strip_types_callback => $_[0]->_jmap_response_strip_types_callback,
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

  $self->_jmap_response_abort_callback->(
    sprintf qq{expected sentence named "%s" but got "%s"}, $name, $self->name
  );
}

1;
