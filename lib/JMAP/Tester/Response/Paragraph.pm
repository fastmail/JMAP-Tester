use v5.10.0;
package JMAP::Tester::Response::Paragraph;
# ABSTRACT: a group of sentences in a JMAP response

use Moo;

=head1 OVERVIEW

These objects represent paragraphs in the JMAP response.  That is, if your
response is:

  [
    [ "messages", { ... }, "a" ],      # 1
    [ "smellUpdates", { ... }, "b" ],  # 2
    [ "smells",       { ... }, "b" ],  # 3
  ]

...then #1 forms one paragraph and #2 and #3 together form another.  It goes by
matching client ids.

=cut

has sentences => (is => 'bare', reader => '_sentences', required => 1);

=method sentences

The C<sentences> method returns a list of
L<Sentence|JMAP::Tester::Response::Sentence> objects, one for each sentence
in the paragraph.

=cut

sub sentences { @{ $_[0]->_sentences } }

=method single

  my $sentence = $para->single;
  my $sentence = $para->single($name);

This method throws an exception if there is more than one sentence in the
paragraph.  If a C<$name> argument is given and the paragraph's single
sentence doesn't have that name, an exception is raised.

Otherwise, this method reeturns the sentence.

=cut

sub single {
  my ($self, $name) = @_;

  my @sentences = $self->sentences;

  Carp::confess("more than one sentence in set, but ->single called")
    if @sentences > 1;

  Carp::confess("single sentence not of expected name <$name>")
    if defined $name && $name ne $sentences[0]->name;

  return $sentences[0];
}

=method as_struct

This method returns an arrayref containing the result of calling C<as_struct>
on each sentence in the paragraph.

=cut

sub as_struct {
  [ map {; $_->as_struct } $_[0]->sentences ]
}

=method as_pairs

This method returns an arrayref containing the result of calling C<as_pair>
on each sentence in the paragraph.

=cut

sub as_pairs {
  [ map {; $_->as_pair } $_[0]->sentences ]
}

1;

