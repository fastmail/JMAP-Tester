use v5.20.0;

package JMAP::Tester::Result::Failure;
# ABSTRACT: what you get when your JMAP request utterly fails

use Moo;
with 'JMAP::Tester::Role::HTTPResult';

use experimental 'signatures';

use Sub::Install ();

use namespace::clean;

=head1 OVERVIEW

This is the sort of worthless object you get back when your JMAP request fails.
This class should be replaced, in most cases, by more useful classes in the
future.

It's got an C<is_success> method.  It returns false. It also has:

=method ident

An error identifier. May or may not be defined.

=cut

sub is_success { 0 }

has ident => (is => 'ro', predicate => 'has_ident');

for my $method (qw(
  sentence
  sentences
  single_sentence
  sentence_named
  assert_n_sentences
  paragraph
  paragraphs
  assert_n_paragraphs
  paragraph_by_client_id
  as_triples
  as_stripped_triples
  as_pairs
  as_stripped_pairs

  wrapper_properties
)) {
  Sub::Install::install_sub({
    into => __PACKAGE__,
    as   => $method,
    code => sub ($self, @) {
      $self->abort("tried to call Response method $method on a Failure", [ Result => $self ]);
    }
  });
}

1;
