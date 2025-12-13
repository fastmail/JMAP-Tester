use v5.20.0;
use warnings;

use experimental 'signatures';

use JMAP::Tester;
use JMAP::Tester::Sugar qw(json_literal);
use JSON::Typist 0.005; # $typist->number

use HTTP::Response;
use LWP::Protocol::PSGI;
use Plack::Request;
use Test::Deep ':v1';
use Test::Deep::JType 0.005; # jstr() in both want and have
use Test::More;
use Test::Abortable 'subtest';

my $api_uri   = 'http://localhost:5627/jmap';
my $psgi_app  = sub ($env) {
  my $req   = Plack::Request->new($env);
  my $body  = $req->raw_body;
  my $data  = JSON::XS->new->decode($body);

  return [
    200,
    [
      'Content-Type' => 'application/json; charset=utf-8',
      'Mock-Server'  => 'gorp/1.23',
    ],
    [
      JSON::XS->new->encode({
        methodResponses => [
          [ 'Fake/one', { f => 1 }, 'a' ],
          [ 'Fake/echo', { echo => $data }, 'c' ],
        ],
      }),
    ]
  ];
};

LWP::Protocol::PSGI->register($psgi_app, host => 'localhost:5627');

my $tester = JMAP::Tester->new({
  api_uri => $api_uri,
});

my @cases = (
  [ "from Perl struct"  => [[ 'Shine/get', { clean => 1 } ]] ],
  [ "from JSON literal" => json_literal(q!
      { "methodCalls": [["Shine/get",   {"clean":1}, "a"]   ]}
    !)
  ]
);

for my $case (@cases) {
  my ($desc, $input) = @$case;
  subtest $desc => sub {
    my $res = $tester->request($input);

    jcmp_deeply($res->sentence(0)->name, "Fake/one", "first name correct");
    jcmp_deeply($res->sentence(0)->arguments, { f => 1 }, "first args correct");

    jcmp_deeply($res->sentence(1)->name, "Fake/echo", "second name correct");
    jcmp_deeply(
      $res->sentence(1)->arguments->{echo},
      superhashof({ methodCalls => [[ 'Shine/get', { clean => 1 }, jstr() ]] }),
      "second args correct",
    );

    like(
      $res->response_payload,
      qr{^Mock-Server: gorp/1\.23$}m,
      "http req stringifies in response"
    );
  };
}

subtest "bogus use of json_literal" => sub {
  my $res = $tester->request([
    [ 'Bogus/call', { arg => json_literal("This will not appear") } ],
  ]);

  my $echoed_args = $res->sentence_named('Fake/echo')->arguments;
  like($echoed_args->{echo}{methodCalls}[0][1]{arg}, qr/ERROR/, "error report in response");
  unlike($echoed_args->{echo}{methodCalls}[0][1]{arg}, qr/not appear/, "we lost requested literal");
};

done_testing;
