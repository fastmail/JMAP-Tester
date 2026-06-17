use v5.20.0;
package JMAP::Tester::SentenceBroker;

use Moo;
with 'JMAP::Tester::Role::SentenceBroker';

use experimental 'signatures';

use Data::OptList ();
use JMAP::Tester::Abort;
use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;

has response => (
  is => 'ro',
  weak_ref => 1,
  required => 1,
);

sub client_ids_for_items ($self, $items_ref) {
  map {; $_->[2] } @$items_ref;
}

sub sentence_for_item ($self, $item) {
  return JMAP::Tester::Response::Sentence->new({
    name      => $item->[0],
    arguments => $item->[1],
    client_id => $item->[2],

    sentence_broker => $self,
  });
}

sub paragraph_for_items ($self, $items_ref) {
  return JMAP::Tester::Response::Paragraph->new({
    sentences       => [ map {; $self->sentence_for_item($_) } @$items_ref ],
  });
}

sub strip_json_types ($self, $struct) {
  state $typist = JSON::Typist->new;
  $typist->strip_types($struct);
}

no Moo;
1;
