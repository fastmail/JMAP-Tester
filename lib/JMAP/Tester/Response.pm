use v5.10.0;

package JMAP::Tester::Response;
# ABSTRACT: what you get in reply to a succesful JMAP request

use Moo;
with 'JMAP::Response', 'JMAP::Tester::Role::Result';

use JMAP::Tester::Abort 'abort';
use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;

use namespace::clean;

=head1 OVERVIEW

A JMAP::Tester::Response object represents the successful response to a JMAP
call.  It is a successful L<JMAP::Tester::Result>.

A Response is used mostly to contain the responses to the individual methods
passed in the request.

=cut

sub is_success { 1 }

has struct => (
  is       => 'bare',
  reader   => '_struct',
  required => 1,
);

has _json_typist => (
  is => 'ro',
  handles => {
    # _strip_json_types => 'strip_types',
  },
);

sub _strip_json_types {
  my ($self, $whatever) = @_;
  $self->_jmap_response_strip_types_callback->($whatever);
}

sub _jmap_response_items {
  @{ $_[0]->_struct }
}

sub _jmap_response_client_ids {
  map {; $_->[2] } @{ $_[0]->_struct }
}

sub _jmap_response_sentence_for_item {
  my ($self, $item) = @_;

  return JMAP::Tester::Response::Sentence->new({
    name      => $item->[0],
    arguments => $item->[1],
    client_id => $item->[2],
    _json_typist => $self->_json_typist,

    _jmap_response_abort_callback       => $self->_jmap_response_abort_callback,
    _jmap_response_strip_types_callback => $self->_jmap_response_strip_types_callback,
  });
}

sub _jmap_response_paragraph_for_items {
  my ($self, $items) = @_;

  return JMAP::Tester::Response::Paragraph->new({
    sentences => [
      map {; $self->_jmap_response_sentence_for_item($_) } @$items
    ],
    _json_typist => $self->_json_typist,
  });
}

sub _jmap_response_abort_callback { \&abort }

sub _jmap_response_strip_types_callback {
  my $typist = (shift)->_json_typist;
  return sub { $typist->strip_types(@_) };
}

1;
