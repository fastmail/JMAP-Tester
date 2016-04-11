use v5.10.0;
use warnings;

package JMAP::Tester;
use Moo;

use Encode qw(encode_utf8);
use JMAP::Tester::Response;

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
    strip_json_types => 'strip_types',
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

has _request_callback => (
  is => 'ro',
  default => sub {
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    return sub { my $self = shift; $ua->request(@_) }
  },
);

sub request {
  my ($self, $calls) = @_;

  state $ident = 'a';
  my @suffixed = map {; [ $_->[0], $_->[1], $_->[2] // $ident++ ] } @$calls;

  my $json = $self->json_encode(\@suffixed);

  my $post = HTTP::Request->new(
    POST => $self->jmap_uri,
    [
      'Content-Type' => 'application/json',
    ],
    encode_utf8($json),
  );

  my $request_cb = $self->_request_callback;
  my $http_res = $self->$request_cb($post);

  unless ($http_res->is_success) {
    return JMAP::Tester::Result::Failure->new({
      http_response => $http_res,
    });
  }

  # TODO check that it's really application/json!

  my $data = $self->apply_json_types(
    $self->json_decode( $http_res->decoded_content )
  );

  return JMAP::Tester::Response->new({
    struct => $data,
  });
}

1;
