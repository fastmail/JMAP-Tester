use v5.10.0;

package JMAP::Tester::Response;
# ABSTRACT: what you get in reply to a succesful JMAP request

use Moo;
with 'JMAP::Tester::Role::SentenceCollection', 'JMAP::Tester::Role::HTTPResult';

use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;
use JMAP::Tester::SentenceBroker;

use namespace::clean;

=head1 OVERVIEW

A JMAP::Tester::Response object represents the successful response to a JMAP
call.  It is a successful L<JMAP::Tester::Result>.

A Response is used mostly to contain the responses to the individual methods
passed in the request.

=cut

sub is_success { 1 }

has items => (
  is       => 'bare',
  reader   => '_items',
  required => 1,
);

has wrapper_properties => (
  is       => 'ro',
);

sub items { @{ $_[0]->_items } }

sub add_items {
  $_[0]->sentence_broker->abort("can't add items to " . __PACKAGE__);
}

sub sentence_broker;
has sentence_broker => (
  is    => 'ro',
  lazy  => 1,
  init_arg => undef,
  default  => sub {
    my ($self) = @_;
    JMAP::Tester::SentenceBroker->new({ response => $self });
  },
);

1;
