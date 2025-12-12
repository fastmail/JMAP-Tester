use v5.20.0;
package JMAP::Tester::Response::Paragraph;
# ABSTRACT: a group of sentences in a JMAP response

use Moo;
use experimental 'signatures';

use JMAP::Tester::Abort 'abort';

use namespace::clean;

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

sub client_id ($self) {
  $self->_sentences->[0]->client_id;
}

sub BUILD {
  abort("tried to build 0-sentence paragraph")
    unless @{ $_[0]->_sentences };

  my $client_id = $_[0]->_sentences->[0]->client_id;
  abort("tried to build paragraph with non-uniform client_ids")
    if grep {; $_->client_id ne $client_id } @{ $_[0]->_sentences };
}

has sentences => (is => 'bare', reader => '_sentences', required => 1);

=method sentences

The C<sentences> method returns a list of
L<Sentence|JMAP::Tester::Response::Sentence> objects, one for each sentence
in the paragraph.

=cut

sub sentences ($self) { @{ $self->_sentences } }

=method sentence

  my $sentence = $para->sentence($n);

This method returns the I<n>th sentence of the paragraph.

=cut

sub sentence ($self, $n) {
  abort("there is no sentence for index $n")
    unless $self->_sentences->[$n];
}

=method single

  my $sentence = $para->single;
  my $sentence = $para->single($name);

This method throws an exception if there is more than one sentence in the
paragraph.  If a C<$name> argument is given and the paragraph's single
sentence doesn't have that name, an exception is raised.

Otherwise, this method returns the sentence.

=cut

sub single ($self, $name = undef) {
  my @sentences = $self->sentences;

  abort("more than one sentence in paragraph, but ->single called")
    if @sentences > 1;

  Carp::confess("single sentence not of expected name <$name>")
    if defined $name && $name ne $sentences[0]->name;

  return $sentences[0];
}

=method assert_n_sentences

  my ($s1, $s2, ...) = $paragraph->assert_n_sentences($n);

This method returns all the sentences in the paragarph, as long as there are
exactly C<$n>.  Otherwise, it aborts.

=cut

sub assert_n_sentences ($self, $n) {
  Carp::confess("no sentence count given") unless defined $n;

  my @sentences = $self->sentences;

  unless (@sentences == $n) {
    abort("expected $n sentences but got " . @sentences)
  }

  return @sentences;
}

=method sentence_named

  my $sentence = $paragraph->sentence_named($name);

This method returns the sentence with the given name.  If no such sentence
exists, or if two sentences with the name exist, the tester will abort.

=cut

sub sentence_named ($self, $name) {
  Carp::confess("no name given") unless defined $name;

  my @sentences = grep {; $_->name eq $name } $self->sentences;

  unless (@sentences) {
    abort(qq{no sentence found with name "$name"});
  }

  if (@sentences > 1) {
    abort(qq{found more than one sentence with name "$name"});
  }

  return $sentences[0];
}

=method as_triples

=method as_stripped_triples

C<as_triples> returns an arrayref containing the result of calling
C<as_triple> on each sentence in the paragraph. C<as_stripped_triples> removes
JSON types.

=cut

sub as_triples ($self) {
  [ map {; $_->as_triple } $self->sentences ]
}

sub as_stripped_triples ($self) {
  [ map {; $_->as_stripped_triple } $self->sentences ]
}

=method as_pairs

C<as_pairs> returns an arrayref containing the result of calling C<as_pair>
on each sentence in the paragraph. C<as_stripped_pairs> removes JSON types.

=cut

sub as_pairs ($self) {
  [ map {; $_->as_pair } $self->sentences ]
}

sub as_stripped_pairs ($self) {
  [ map {; $_->as_stripped_pair } $self->sentences ]
}

1;
