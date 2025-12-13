use v5.20.0;

package JMAP::Tester::Response;
# ABSTRACT: what you get in reply to a succesful JMAP request

use Moo;
use experimental 'signatures';

# We can't use 'sub sentencebroker;' as a stub here as it conflicts
# with older Role::Tiny versions (2.000006, 2.000008, and others).
# With the stub, we'd see this error during compilation:
#
# Can't use string ("-1") as a symbol ref while "strict refs" in use at
# /usr/share/perl5/Role/Tiny.pm line 382
#
# We could pin a newer Role::Tiny version but this fix is easy enough

has sentence_broker => (
  is    => 'ro',
  lazy  => 1,
  init_arg => undef,
  default  => sub {
    my ($self) = @_;
    JMAP::Tester::SentenceBroker->new({ response => $self });
  },
);

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

sub items ($self) { @{ $self->_items } }

sub add_items ($self, @) {
  $self->sentence_broker->abort("can't add items to " . __PACKAGE__);
}

sub default_diagnostic_dumper {
  state $default = do {
    require JSON::MaybeXS;
    state $json = JSON::MaybeXS->new->utf8->convert_blessed->pretty->canonical;
    sub ($value) { $json->encode($value); }
  };

  return $default;
}

has _diagnostic_dumper => (
  is => 'ro',
  builder   => 'default_diagnostic_dumper',
  init_arg  => 'diagnostic_dumper',
);

sub dump_diagnostic ($self, $value) {
  $self->_diagnostic_dumper->($value);
}

1;
