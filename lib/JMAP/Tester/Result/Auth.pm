use v5.10.0;
use strict;

package JMAP::Tester::Result::Auth;
# ABSTRACT: what you get when you authenticate

use Moo;
with 'JMAP::Tester::Role::Result';

use namespace::clean;

=head1 OVERVIEW

This is what you get when you authenticate!  It's got an C<is_success> method.
It returns true.

=cut

sub is_success { 1 }

has client_session => (
  is => 'ro',
);

1;
