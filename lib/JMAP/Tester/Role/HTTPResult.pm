use v5.10.0;
use warnings;
package JMAP::Tester::Role::HTTPResult;
# ABSTRACT: the kind of thing that you get back for an http request

use Moo::Role;

with 'JMAP::Tester::Role::Result';

=head1 OVERVIEW

This is the role consumed by the class of any object returned by
L<JMAP::Tester>'s C<request> method.  In addition to
L<JMAP::Tester::Role::Result>, this role provides C<http_response> to
get at the underlying L<HTTP::Response> object. C<response_payload> will
come from the C<as_string> method of that object.

=cut

has http_response => (
  is => 'ro',
);

=method response_payload

Returns the raw payload of the response, if there is one. Empty string
otherwise. Mostly this will be C<< $self->http_response->as_string >>
but other result types may exist that don't have an http_response...

=cut

sub response_payload {
  my ($self) = @_;

  return $self->http_response ? $self->http_response->as_string : '';
}

1;
