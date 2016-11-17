use v5.10.0;
use strict;

package JMAP::Tester::Result::Auth;
# ABSTRACT: what you get when you authenticate

use Moo;
with 'JMAP::Tester::Role::Result';

=head1 OVERVIEW

This is what you get when you authenticate!  It's got an C<is_success> method.
It returns true.

=cut

sub is_success { 1 }

has auth_struct => (
  is => 'ro',
);

1;
