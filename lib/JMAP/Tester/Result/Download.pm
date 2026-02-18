use v5.20.0;

package JMAP::Tester::Result::Download;
# ABSTRACT: what you get when you download a blob

use Moo;
with 'JMAP::Tester::Role::HTTPResult';

use namespace::clean;

=head1 OVERVIEW

A JMAP::Tester::Result::Download object represents the successful download of a
JMAP blob.  It is a successful L<JMAP::Tester::Role::HTTPResult>, meaning it
has a C<http_response> method that returns an L<HTTP::Response> object.

=method bytes_ref

The raw bytes of the blob.

It also has a C<bytes_ref> method which will return a reference to the
raw bytes of the download.

=cut

sub is_success { 1 }

has bytes_ref => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    my $str = $_[0]->http_response->decoded_content(charset => 'none');
    return \$str;
  },
);

1;
