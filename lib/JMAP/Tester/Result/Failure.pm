use v5.10.0;
use strict;

package JMAP::Tester::Result::Failure;
# ABSTRACT: what you get when your JMAP request utterly fails

use Moo;
with 'JMAP::Tester::Role::Result';

=head1 OVERVIEW

This is the sort of worthless object you get back when your JMAP request fails.
This class should be replaced, in most cases, by more useful classes in the
future.

It's got an C<is_success> method.  It returns false.

=cut

sub is_success { 0 }

has ident => (is => 'ro', predicate => 'has_ident');

1;
