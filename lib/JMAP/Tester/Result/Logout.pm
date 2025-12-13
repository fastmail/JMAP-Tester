use v5.20.0;

package JMAP::Tester::Result::Logout;
# ABSTRACT: a successful logout

use Moo;
with 'JMAP::Tester::Role::HTTPResult';

use namespace::clean;

=head1 OVERVIEW

It's got an C<is_success> method.  It returns true.  Yup.

=cut

sub is_success { 1 }

1;
