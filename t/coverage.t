use strict;
use warnings;

use File::Temp ();
use HTTP::Response;
use JMAP::Tester;
use JMAP::Tester::Response;
use JMAP::Tester::Result::Failure;
use JSON::Typist 0.005; # $typist->number

use Scalar::Util 'blessed';
use Test::Deep ':v1';
use Test::Deep::JType 0.005; # jstr() in both want and have
use Test::Fatal;
use Test::More;
use Test::Abortable 'subtest';

subtest "test accessors on Sentence::Set" => sub {
  my $res = JMAP::Tester::Response->new({
    items => [
      [
        'Widget/set' => {
          oldState => jstr('state-1'),
          newState => jstr('state-2'),
          created  => {
            cr0 => { id => 'x100', size => jnum(42) },
            cr1 => { id => 'x101', size => jnum(13) },
          },
          updated    => { 'x200' => undef, 'x201' => { color => 'red' } },
          destroyed  => [ 'x300', 'x301' ],
          notCreated   => {
            cr2 => { type => jstr('invalidProperties') },
          },
          notUpdated   => {
            x202 => { type => jstr('notFound') },
          },
          notDestroyed => {
            x302 => { type => jstr('notFound') },
          },
        },
        'a',
      ],
    ],
  });

  my $s = $res->single_sentence('Widget/set')->as_set;

  is($s->old_state, 'state-1', "old_state");
  is($s->new_state, 'state-2', "new_state");

  is($s->as_set, $s, "as_set on a Set is identity");

  jcmp_deeply(
    $s->created,
    { cr0 => superhashof({}), cr1 => superhashof({}) },
    "created gets us back the created hashref",
  );

  is($s->created_id('cr0'), 'x100', "created_id cr-0");
  is($s->created_id('cr1'), 'x101', "created_id cr-1");
  is($s->created_id('cr-nope'), undef, "created_id for unknown");

  jcmp_deeply(
    [ $s->created_creation_ids ],
    bag(qw( cr0 cr1 )),
    "created_creation_ids"
  );

  jcmp_deeply([ $s->created_ids ],   bag(qw(x100 x101)), "created_ids");
  jcmp_deeply([ $s->updated_ids ],   bag(qw(x200 x201)), "updated_ids");
  jcmp_deeply([ $s->destroyed_ids ], bag(qw(x300 x301)), "destroyed_ids");

  jcmp_deeply([ $s->not_created_ids ],   bag('cr2' ), "not_created_ids");
  jcmp_deeply([ $s->not_updated_ids ],   bag('x202'), "not_updated_ids");
  jcmp_deeply([ $s->not_destroyed_ids ], bag('x302'), "not_destroyed_ids");

  jcmp_deeply(
    $s->create_errors,
    { cr2 => { type => jstr('invalidProperties') } },
    "create_errors",
  );

  jcmp_deeply(
    $s->update_errors,
    { x202 => { type => jstr('notFound') } },
    "update_errors",
  );

  jcmp_deeply(
    $s->destroy_errors,
    { x302 => { type => jstr('notFound') } },
    "destroy_errors",
  );
};

subtest "test accessors on Sentence::Set with omitted arguments" => sub {
  # When the set response has none of the standard fields at all, we should
  # still be okay. -- claude, 2025-02-08
  my $res = JMAP::Tester::Response->new({
    items => [
      [ 'Thing/set' => { newState => 'state-3' }, 'a' ],
    ],
  });

  my $s = $res->single_sentence('Thing/set')->as_set;

  jcmp_deeply($s->created,        {}, "created defaults to {}");
  jcmp_deeply($s->create_errors,  {}, "create_errors defaults to {}");
  jcmp_deeply($s->update_errors,  {}, "update_errors defaults to {}");
  jcmp_deeply($s->destroy_errors, {}, "destroy_errors defaults to {}");

  is($s->created_id('anything'), undef, "created_id with bogus input yields undef");
  jcmp_deeply([ $s->created_creation_ids ], [], "no created_creation_ids");
  jcmp_deeply([ $s->created_ids ], [], "no created_ids");

  is($s->assert_no_errors, $s, "returns self with no error fields at all");
};

subtest "assert_no_errors" => sub {
  my $res = JMAP::Tester::Response->new({
    items => [
      [ 'Widget/set' => {
          created   => { cr0 => { id => 'x100' } },
          updated   => { x200 => undef },
          destroyed => [ 'x300' ],
        }, 'a' ],
    ],
  });

  my $s = $res->single_sentence('Widget/set')->as_set;
  is($s->assert_no_errors, $s, "returns self when clean");
};

subtest "assert_successful and friends" => sub {
  my $ok_res = JMAP::Tester::Response->new({
    items => [
      [ 'Widget/set' => {
          created   => { cr0 => { id => 'x1' } },
          updated   => {},
          destroyed => [],
        }, 'a' ],
    ],
  });

  is($ok_res->assert_successful, $ok_res, "assert_successful on success");

  {
    my $s = $ok_res->assert_successful_set('Widget/set');
    isa_ok($s, 'JMAP::Tester::Response::Sentence::Set');
  }

  {
    my $s = $ok_res->assert_single_successful_set('Widget/set');
    isa_ok($s, 'JMAP::Tester::Response::Sentence::Set');
  }

  {
    my $s = $ok_res->assert_single_successful_set;
    isa_ok($s, 'JMAP::Tester::Response::Sentence::Set');
  }

  # Now for the failure cases.
  {
    my $fail = JMAP::Tester::Result::Failure->new({
      http_response => HTTP::Response->new(500, "Internal Server Error"),
    });

    ok(! $fail->is_success, "failure is not success");

    my $err = exception { $fail->assert_successful };
    isa_ok($err, 'JMAP::Tester::Abort', "assert_successful's throw");
    like($err->message, qr/JMAP failure/, "default message for ident-less failure");
  }

  {
    my $fail = JMAP::Tester::Result::Failure->new({
      ident         => "custom error ident",
      http_response => HTTP::Response->new(500, "Internal Server Error"),
    });

    ok($fail->has_ident, "failure has_ident");
    is($fail->ident, "custom error ident", "ident value");

    my $err = exception { $fail->assert_successful };
    isa_ok($err, 'JMAP::Tester::Abort', "assert_successful's throw");
    like($err->message, qr/custom error ident/, "abort message uses ident");
  }
};

subtest "response_payload" => sub {
  {
    my $fail = JMAP::Tester::Result::Failure->new({
      http_response => HTTP::Response->new(
        500, "Oops",
        [ 'Content-Type' => 'text/plain' ],
        "something went wrong",
      ),
    });

    like(
      $fail->response_payload,
      qr/something went wrong/,
      "response_payload includes body"
    );
  }

  {
    my $fail = JMAP::Tester::Result::Failure->new;
    is($fail->response_payload, '', "no http_response means empty payload");
  }
};

done_testing;
