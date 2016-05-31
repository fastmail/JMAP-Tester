use v5.10.0;
use warnings;
package JMAP::Tester::Role::Result;
# ABSTRACT: the kind of thing that you get back for a request

use Moo::Role;

=head1 OVERVIEW

This is the role consumed by the class of any object returned by JMAP::Tester's
C<request> method.  Its only guarantee, for now, is an C<is_success> method.

=cut

requires 'is_success';

1;
