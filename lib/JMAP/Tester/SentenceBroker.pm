use v5.10.0;
package JMAP::Tester::SentenceBroker;

use Moo;
with 'JMAP::Tester::Role::SentenceBroker';

use JMAP::Tester::Abort;
use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;

has response => (
  is => 'ro',
  weak_ref => 1,
  required => 1,
);

sub client_ids_for_items {
  map {; $_->[2] } @{ $_[1] }
}

sub sentence_for_item {
  my ($self, $item) = @_;

  return JMAP::Tester::Response::Sentence->new({
    name      => $item->[0],
    arguments => $item->[1],
    client_id => $item->[2],

    sentence_broker => $self,
  });
}

sub paragraph_for_items {
  my ($self, $items) = @_;

  return JMAP::Tester::Response::Paragraph->new({
    sentences       => [ map {; $self->sentence_for_item($_) } @$items ],
  });
}

sub abort {
  my ($self, $string, $diagnostics) = @_;

  die JMAP::Tester::Abort->new({
    message => $string,
    ($diagnostics ? (diagnostics => $diagnostics) : ()),
  });
}

sub strip_json_types {
  state $typist = JSON::Typist->new;
  $typist->strip_types($_[1]);
}

no Moo;
__PACKAGE__->meta->make_immutable;
