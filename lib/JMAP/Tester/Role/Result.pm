use v5.20.0;
use warnings;
package JMAP::Tester::Role::Result;
# ABSTRACT: the kind of thing that you get back for a request

use Moo::Role;

use experimental 'signatures';

use JMAP::Tester::Abort ();

use namespace::clean;

=head1 OVERVIEW

This is the role consumed by the class of any object returned by JMAP::Tester's
C<request> method.  Its only guarantee, for now, is an C<is_success> method,
and a C<response_payload> method.

=cut

requires 'is_success';
requires 'response_payload';

=method assert_successful

This method returns the result if it's a success and otherwise aborts.

=cut

sub assert_successful ($self) {
  return $self if $self->is_success;

  my $str = $self->can('has_ident') && $self->has_ident
          ? $self->ident
          : "JMAP failure";

  die JMAP::Tester::Abort->new($str);
}

=method assert_successful_set

  $result->assert_successful_set($name);

This method is equivalent to:

  $result->assert_successful->sentence_named($name)->as_set->assert_no_errors;

C<$name> must be provided.

=cut

sub assert_successful_set ($self, $name) {
  $self->assert_successful->sentence_named($name)->as_set->assert_no_errors;
}

=method assert_single_successful_set

  $result->assert_single_successful_set($name);

This method is equivalent to:

  $result->assert_successful->single_sentence($name)->as_set->assert_no_errors;

C<$name> may be omitted, in which case the sentence name is not checked.

=cut

sub assert_single_successful_set ($self, $name = undef) {
  $self->assert_successful->single_sentence($name)->as_set->assert_no_errors;
}

1;
