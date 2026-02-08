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

subtest "set sentence accessors" => sub {
  my $res = JMAP::Tester::Response->new({
    items => [
      [
        'Widget/set' => {
          oldState => jstr('state-1'),
          newState => jstr('state-2'),
          created  => {
            'cr-0' => { id => 'x100', size => jnum(42) },
            'cr-1' => { id => 'x101', size => jnum(13) },
          },
          updated    => { 'x200' => undef, 'x201' => { color => 'red' } },
          destroyed  => [ 'x300', 'x301' ],
          notCreated   => {
            'cr-2' => { type => jstr('invalidProperties') },
          },
          notUpdated   => {
            'x202' => { type => jstr('notFound') },
          },
          notDestroyed => {
            'x302' => { type => jstr('notFound') },
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

  is(ref $s->created, 'HASH',     "created is a hashref");
  is(keys %{ $s->created }, 2,    "two created entries");
  is($s->created_id('cr-0'), 'x100', "created_id cr-0");
  is($s->created_id('cr-1'), 'x101', "created_id cr-1");
  is($s->created_id('cr-nope'), undef, "created_id for unknown");

  is_deeply([ sort $s->created_creation_ids ], [ 'cr-0', 'cr-1' ],
    "created_creation_ids");

  is_deeply([ sort $s->created_ids ], [ 'x100', 'x101' ], "created_ids");
  is_deeply([ sort $s->updated_ids ], [ 'x200', 'x201' ], "updated_ids");
  is_deeply([ sort $s->destroyed_ids ], [ 'x300', 'x301' ], "destroyed_ids");

  is_deeply([ $s->not_created_ids ],   [ 'cr-2' ], "not_created_ids");
  is_deeply([ $s->not_updated_ids ],   [ 'x202' ], "not_updated_ids");
  is_deeply([ $s->not_destroyed_ids ], [ 'x302' ], "not_destroyed_ids");

  is_deeply(
    $s->create_errors,
    { 'cr-2' => { type => jstr('invalidProperties') } },
    "create_errors",
  );

  is_deeply(
    $s->update_errors,
    { 'x202' => { type => jstr('notFound') } },
    "update_errors",
  );

  is_deeply(
    $s->destroy_errors,
    { 'x302' => { type => jstr('notFound') } },
    "destroy_errors",
  );
};

subtest "assert_no_errors" => sub {
  {
    my $res = JMAP::Tester::Response->new({
      items => [
        [ 'Widget/set' => {
            created   => { 'cr-0' => { id => 'x100' } },
            updated   => { 'x200' => undef },
            destroyed => [ 'x300' ],
          }, 'a' ],
      ],
    });

    my $s = $res->single_sentence('Widget/set')->as_set;
    is($s->assert_no_errors, $s, "returns self when clean");
  }

  # When the set response has none of the standard fields at all, we should
  # still be okay. -- rjbs, 2025-02-08
  {
    my $res = JMAP::Tester::Response->new({
      items => [
        [ 'Thing/set' => { newState => 'state-3' }, 'a' ],
      ],
    });

    my $s = $res->single_sentence('Thing/set')->as_set;

    is_deeply($s->created,        {}, "created defaults to {}");
    is_deeply($s->create_errors,  {}, "create_errors defaults to {}");
    is_deeply($s->update_errors,  {}, "update_errors defaults to {}");
    is_deeply($s->destroy_errors, {}, "destroy_errors defaults to {}");

    is($s->created_id('anything'), undef, "created_id on empty");
    is_deeply([ $s->created_creation_ids ], [], "no created_creation_ids");
    is_deeply([ $s->created_ids ], [], "no created_ids");

    is($s->assert_no_errors, $s, "returns self with no error fields at all");
  }
};

subtest "assert_successful and friends" => sub {
  my $ok_res = JMAP::Tester::Response->new({
    items => [
      [ 'Widget/set' => {
          created   => { 'cr-0' => { id => 'x1' } },
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
    ok(
      blessed($err) && $err->isa('JMAP::Tester::Abort'),
      "assert_successful throws Abort on failure",
    );
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
    ok(
      blessed($err) && $err->isa('JMAP::Tester::Abort'),
      "assert_successful throws Abort on identified failure",
    );
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

    like($fail->response_payload, qr/something went wrong/,
      "response_payload includes body");
  }

  {
    my $fail = JMAP::Tester::Result::Failure->new({});
    is($fail->response_payload, '', "no http_response means empty payload");
  }
};

subtest "log writers" => sub {
  require JMAP::Tester::LogWriter;

  {
    my @written;
    my $writer = JMAP::Tester::LogWriter::Code->new({
      code => sub { push @written, $_[0] },
    });

    $writer->write("hello");
    $writer->write("world");
    is_deeply(\@written, [ "hello", "world" ], "Code writer");
  }

  {
    my $output = '';
    open my $fh, '>', \$output or die "can't open string fh: $!";
    my $writer = JMAP::Tester::LogWriter::Handle->new({ handle => $fh });

    $writer->write("line one\n");
    $writer->write("line two\n");
    is($output, "line one\nline two\n", "Handle writer");
  }

  {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $template = "$dir/test-{PID}.log";
    my $writer = JMAP::Tester::LogWriter::Filename->new({
      filename_template => $template,
    });

    $writer->write("logged line\n");

    my $fn = "$dir/test-$$.log";
    ok(-f $fn, "Filename writer created file");
    open my $fh, '<', $fn or die "can't read $fn: $!";
    my $content = do { local $/; <$fh> };
    is($content, "logged line\n", "Filename writer content");
  }
};

subtest "logger writer coercion" => sub {
  require JMAP::Tester::Logger::HTTP;

  {
    my @lines;
    my $logger = JMAP::Tester::Logger::HTTP->new({
      writer => sub { push @lines, $_[0] },
    });

    isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Code');
    $logger->write("test");
    is_deeply(\@lines, ["test"], "coderef coercion");
  }

  {
    my $output = '';
    open my $fh, '>', \$output or die $!;
    my $logger = JMAP::Tester::Logger::HTTP->new({ writer => $fh });

    isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Handle');
    $logger->write("test");
    is($output, "test", "handle coercion");
  }

  {
    my $logger = JMAP::Tester::Logger::HTTP->new({ writer => \undef });
    isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Code');
    $logger->write("goes nowhere");
    pass("undef scalar ref becomes no-op Code writer");
  }

  {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $logger = JMAP::Tester::Logger::HTTP->new({
      writer => "$dir/logger-{PID}.log",
    });
    isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Filename');
  }
};

subtest "UA::LWP helpers" => sub {
  require JMAP::Tester::UA::LWP;
  my $ua = JMAP::Tester::UA::LWP->new;

  $ua->set_default_header('X-Test', 'xyzzy');
  is($ua->get_default_header('X-Test'), 'xyzzy', "get/set default header");

  $ua->set_cookie({
    api_uri => 'https://example.com/api/',
    name    => 'session',
    value   => 'abc123',
  });

  my @cookies;
  $ua->scan_cookies(sub { push @cookies, $_[1] });
  ok((grep { $_ eq 'session' } @cookies), "set_cookie + scan_cookies");

  for my $field (qw(api_uri name value)) {
    my %args = (api_uri => 'https://x.com/', name => 'n', value => 'v');
    delete $args{$field};
    my $err = exception { $ua->set_cookie(\%args) };
    like($err, qr/can't set_cookie without $field/, "set_cookie needs $field");
  }
};

subtest "Logger::Null" => sub {
  require JMAP::Tester::Logger::Null;
  my $null = JMAP::Tester::Logger::Null->new({ writer => sub {} });

  for my $method (qw(
    log_jmap_request     log_jmap_response
    log_misc_request     log_misc_response
    log_upload_request   log_upload_response
    log_download_request log_download_response
  )) {
    my $ok = eval { $null->$method(); 1 };
    ok($ok, "$method doesn't die");
  }
};

sub aborts_ok {
  my ($code, $want, $desc);
  if (@_ == 2) {
    ($code, $desc) = @_;
  } elsif (@_ == 3) {
    ($code, $want, $desc) = @_;
  } else {
    Carp::confess("aborts_ok used wrongly");
  }

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $ok = eval { $code->(); 1 };
  my $error = $@;

  if ($ok) {
    fail("code ran without exception: $desc");
    return;
  }

  unless (blessed $error && $error->isa('JMAP::Tester::Abort')) {
    fail("code threw non-abort: $desc");
    diag("error thrown: $error");
    return;
  }

  unless ($want) {
    pass("got an abort: $desc");
    return;
  }

  cmp_deeply(
    $error,
    $want,
    "got expected abort: $desc",
  );
}

done_testing;
