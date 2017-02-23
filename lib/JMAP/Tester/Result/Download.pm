use v5.10.0;
use strict;

package JMAP::Tester::Result::Download;
# ABSTRACT: what you get when you download a blob

use Moo;
with 'JMAP::Tester::Role::Result';

use namespace::clean;

=head1 OVERVIEW

This is what you get when you download!  It's got an C<is_success> method.  It
returns true.

=cut

sub is_success { 1 }

has bytes_ref => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    my $str = $_[0]->http_response->decoded_content(charset => 'none');
    return $str;
  },
);

1;
