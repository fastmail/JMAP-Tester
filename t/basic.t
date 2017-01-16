use strict;
use warnings;

use JMAP::Tester::Response;
use JSON::Typist 0.005; # $typist->number

use Test::Deep;
use Test::Deep::JType 0.005; # jstr() in both want and have
use Test::More;
use Test::Abortable 'subtest';

# ATTENTION:  You're really not meant to just create Response objects.  They're
# supposed to come from Testers.  Doing that in the tests, though, would
# require mocking up a remote end.  Until we're up for doing that, this is
# simpler for testing. -- rjbs, 2016-12-15

my $typist = JSON::Typist->new;

subtest "the basic basics" => sub {
  my $res = JMAP::Tester::Response->new({
    _json_typist => $typist,
    struct => [
      [ atePies => { howMany => jnum(100), tastiestPieId => jstr(123) }, 'a' ],
      [ platesDiscarded => { notDiscarded => [] }, 'a' ],

      [ drankBeer => { abv => jnum(0.02) }, 'b' ],

      [ tookNap => { successfulDuration => jnum(2) }, 'c' ],
      [ dreamed => { about => jstr("more pie") }, 'c' ],
    ],
  });

  my ($p0, $p1, $p2) = $res->assert_n_paragraphs(3);

  is($p0->sentence(0)->name, "atePies",         "p0 s0 name");
  is($p0->sentence(1)->name, "platesDiscarded", "p0 s1 name");
  is($p1->sentence(0)->name, "drankBeer",       "p1 s0 name");
  is($p2->sentence(0)->name, "tookNap",         "p2 s0 name");
  is($p2->sentence(1)->name, "dreamed",         "p2 s1 name");
};

subtest "old style updated" => sub {
  my %kinds = (
    old => [ 'a', 'b' ],
    new => {
      a => undef,
      b => { awesomeness => jstr('high') },
    },
  );

  for my $kind (sort keys %kinds) {
    my $res = JMAP::Tester::Response->new({
      _json_typist => $typist,
      struct => [
        [ setPieces => { updated => $kinds{$kind} }, 'a' ]
      ],
    });

    my $s = $res->single_sentence('setPieces')->as_set;

    is_deeply(
      [ sort $s->updated_ids ],
      [ qw(a b) ],
      "we can get updated_ids from $kind style updated",
    );

    my $want = ref $kinds{$kind} eq 'HASH'
             ? $kinds{$kind}
             : { map {; $_ => undef } @{ $kinds{$kind} } };

    is_deeply($s->updated, $want, "can get updated from $kind style updated");
  }
};

subtest "aborts" => sub {
  my $events = Test2::API::intercept(sub {
    subtest "this will abort" => sub {
      my $res = JMAP::Tester::Response->new({
        _json_typist => $typist,
        struct => [
          [ atePies => { howMany => jnum(100), tastiestPieId => jstr(123) }, 'a' ],
        ],
      });

      my $s = $res->single_sentence('piesEt');
      pass("okay");
    };
  });

  my ($subtest) = grep { $_->isa('Test2::Event::Subtest') } @$events;
  my @pass = grep { $_->isa('Test2::Event::Ok') } @{ $subtest->subevents };
  is(@pass, 1, "aborted subtest emits just one ok");
  ok($pass[0]->causes_fail, "and it's a failure");
  isnt(
    index($pass[0]->name, 'single sentence has name "atePies" not "piesEt"'),
    -1,
    "and it's the abort we expect",
  );
};

done_testing;
