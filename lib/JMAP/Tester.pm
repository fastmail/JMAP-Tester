use v5.10.0;
use warnings;

package JMAP::Tester;
use Moo;

use Encode qw(encode_utf8);
use JMAP::Tester::RequestResponse;

has json_codec => (
  is => 'bare',
  handles => {
    json_encode => 'encode',
    json_decode => 'decode',
  },
  default => sub {
    require JSON;
    return JSON->new->allow_blessed->convert_blessed;
  },
);

has json_typist => (
  is => 'bare',
  handles => {
    apply_json_types => 'apply_types',
  },
  default => sub {
    require JSON::Typist;
    return JSON::Typist->new;
  },
);

has jmap_uri => (
  is => 'ro',
  required => 1,
);

has _ua => (
  is => 'ro',
  default => sub {
    require LWP::UserAgent;
    return LWP::UserAgent->new;
  },
);

sub request {
  my ($self, $calls) = @_;

  state $ident = 'a';
  my @suffixed = map {; [ $_->[0], $_->[1], $ident++ ] } @$calls;

  my $json = $self->json_encode(\@suffixed);

  my $http_res = $self->_ua->post(
    $self->jmap_uri,
    'Content-Type' => 'application/json',
    Content => encode_utf8($json),
  );

  unless ($http_res->is_success) {
    return JMAP::Tester::Result::Failure->new({
      http_response => $http_res,
    });
  }

  # TODO check that it's really application/json!

  my $data = $self->apply_json_types(
    $self->json_decode( $http_res->decoded_content )
  );

  return JMAP::Tester::RequestResponse->new({
    response => $data,
  });
}

1;
