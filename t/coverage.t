use v5.20.0;
use warnings;

use experimental 'signatures';

use HTTP::Response;
use JMAP::Tester;
use JMAP::Tester::Response;
use JMAP::Tester::Result::Failure;
use JSON::Typist 0.005;

use Scalar::Util 'blessed';
use Test::Deep ':v1';
use Test::Deep::JType 0.005;
use Test::Fatal;
use Test::More;
use Test::Abortable 'subtest';

# Re-use aborts_ok from basic.t
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

subtest "Sentence::Set accessors" => sub {
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

  my $set = $res->single_sentence('Widget/set')->as_set;

  is($set->old_state, 'state-1', "old_state");
  is($set->new_state, 'state-2', "new_state");

  # as_set on a Set returns itself
  is($set->as_set, $set, "as_set on a Set returns self");

  # created
  is(ref $set->created, 'HASH', "created returns a hashref");
  is(keys %{ $set->created }, 2, "two created entries");

  # created_id
  is($set->created_id('cr-0'), 'x100', "created_id for cr-0");
  is($set->created_id('cr-1'), 'x101', "created_id for cr-1");
  is($set->created_id('cr-nope'), undef, "created_id for nonexistent");

  # created_creation_ids
  is_deeply(
    [ sort $set->created_creation_ids ],
    [ 'cr-0', 'cr-1' ],
    "created_creation_ids",
  );

  # created_ids
  is_deeply(
    [ sort $set->created_ids ],
    [ 'x100', 'x101' ],
    "created_ids",
  );

  # updated_ids (hash form)
  is_deeply(
    [ sort $set->updated_ids ],
    [ 'x200', 'x201' ],
    "updated_ids from hash",
  );

  # destroyed_ids
  is_deeply(
    [ sort $set->destroyed_ids ],
    [ 'x300', 'x301' ],
    "destroyed_ids",
  );

  # not_created_ids
  is_deeply(
    [ $set->not_created_ids ],
    [ 'cr-2' ],
    "not_created_ids",
  );

  # not_updated_ids
  is_deeply(
    [ $set->not_updated_ids ],
    [ 'x202' ],
    "not_updated_ids",
  );

  # not_destroyed_ids
  is_deeply(
    [ $set->not_destroyed_ids ],
    [ 'x302' ],
    "not_destroyed_ids",
  );

  # create_errors / update_errors / destroy_errors
  is_deeply(
    $set->create_errors,
    { 'cr-2' => { type => jstr('invalidProperties') } },
    "create_errors",
  );

  is_deeply(
    $set->update_errors,
    { 'x202' => { type => jstr('notFound') } },
    "update_errors",
  );

  is_deeply(
    $set->destroy_errors,
    { 'x302' => { type => jstr('notFound') } },
    "destroy_errors",
  );
};

subtest "Sentence::Set with no errors" => sub {
  my $res = JMAP::Tester::Response->new({
    items => [
      [
        'Widget/set' => {
          oldState  => 'state-1',
          newState  => 'state-2',
          created   => { 'cr-0' => { id => 'x100' } },
          updated   => { 'x200' => undef },
          destroyed => [ 'x300' ],
        },
        'a',
      ],
    ],
  });

  my $set = $res->single_sentence('Widget/set')->as_set;

  my $returned = $set->assert_no_errors;
  is($returned, $set, "assert_no_errors returns self when no errors");
};

subtest "Sentence::Set with missing optional fields" => sub {
  # A set response that has none of the notFoo fields
  my $res = JMAP::Tester::Response->new({
    items => [
      [
        'Thing/set' => {
          newState => 'state-3',
        },
        'a',
      ],
    ],
  });

  my $set = $res->single_sentence('Thing/set')->as_set;

  is_deeply($set->created, {}, "created defaults to empty hashref");
  is_deeply($set->create_errors, {}, "create_errors defaults to empty hashref");
  is_deeply($set->update_errors, {}, "update_errors defaults to empty hashref");
  is_deeply($set->destroy_errors, {}, "destroy_errors defaults to empty hashref");

  is($set->created_id('anything'), undef, "created_id on empty created");
  is_deeply([ $set->created_creation_ids ], [], "no created_creation_ids");
  is_deeply([ $set->created_ids ], [], "no created_ids");

  my $returned = $set->assert_no_errors;
  is($returned, $set, "assert_no_errors passes with no error fields at all");
};

subtest "Role::Result - assert_successful on failure" => sub {
  my $failure = JMAP::Tester::Result::Failure->new({
    http_response => HTTP::Response->new(500, "Internal Server Error"),
  });

  ok(!$failure->is_success, "failure is not success");

  my $err = exception { $failure->assert_successful };
  ok(blessed($err) && $err->isa('JMAP::Tester::Abort'), "assert_successful dies with Abort");
  like($err->message, qr/JMAP failure/, "default abort message");
};

subtest "Role::Result - assert_successful on failure with ident" => sub {
  my $failure = JMAP::Tester::Result::Failure->new({
    ident         => "custom error ident",
    http_response => HTTP::Response->new(500, "Internal Server Error"),
  });

  ok($failure->has_ident, "failure has ident");
  is($failure->ident, "custom error ident", "ident is correct");

  my $err = exception { $failure->assert_successful };
  ok(blessed($err) && $err->isa('JMAP::Tester::Abort'), "assert_successful dies with Abort");
  like($err->message, qr/custom error ident/, "abort uses ident in message");
};

subtest "Role::Result - assert_successful on success" => sub {
  my $res = JMAP::Tester::Response->new({
    items => [
      [ 'Widget/set' => { created => { 'cr-0' => { id => 'x1' } } }, 'a' ],
    ],
  });

  my $returned = $res->assert_successful;
  is($returned, $res, "assert_successful returns the result on success");
};

subtest "Role::Result - assert_successful_set" => sub {
  my $res = JMAP::Tester::Response->new({
    items => [
      [ 'Widget/set' => {
          created   => { 'cr-0' => { id => 'x1' } },
          updated   => {},
          destroyed => [],
        }, 'a' ],
    ],
  });

  my $set = $res->assert_successful_set('Widget/set');
  isa_ok($set, 'JMAP::Tester::Response::Sentence::Set');
};

subtest "Role::Result - assert_single_successful_set" => sub {
  my $res = JMAP::Tester::Response->new({
    items => [
      [ 'Widget/set' => {
          created   => { 'cr-0' => { id => 'x1' } },
          updated   => {},
          destroyed => [],
        }, 'a' ],
    ],
  });

  # with name
  my $set = $res->assert_single_successful_set('Widget/set');
  isa_ok($set, 'JMAP::Tester::Response::Sentence::Set');

  # without name
  my $set2 = $res->assert_single_successful_set;
  isa_ok($set2, 'JMAP::Tester::Response::Sentence::Set');
};

subtest "Role::HTTPResult - response_payload" => sub {
  {
    my $failure = JMAP::Tester::Result::Failure->new({
      http_response => HTTP::Response->new(
        500, "Oops",
        [ 'Content-Type' => 'text/plain' ],
        "something went wrong",
      ),
    });

    like(
      $failure->response_payload,
      qr/something went wrong/,
      "response_payload includes body",
    );
  }

  {
    my $failure = JMAP::Tester::Result::Failure->new({});

    is($failure->response_payload, '', "response_payload is empty without http_response");
  }
};

subtest "LogWriter::Code" => sub {
  require JMAP::Tester::LogWriter;

  my @written;
  my $writer = JMAP::Tester::LogWriter::Code->new({
    code => sub { push @written, $_[0] },
  });

  $writer->write("hello");
  $writer->write("world");

  is_deeply(\@written, [ "hello", "world" ], "Code writer forwards to coderef");
};

subtest "LogWriter::Handle" => sub {
  require JMAP::Tester::LogWriter;

  my $output = '';
  open my $fh, '>', \$output or die "can't open string fh: $!";

  my $writer = JMAP::Tester::LogWriter::Handle->new({ handle => $fh });

  $writer->write("line one\n");
  $writer->write("line two\n");

  is($output, "line one\nline two\n", "Handle writer prints to handle");
};

subtest "LogWriter::Filename" => sub {
  require JMAP::Tester::LogWriter;
  require File::Temp;

  my $dir = File::Temp::tempdir(CLEANUP => 1);
  my $template = "$dir/test-{PID}.log";

  my $writer = JMAP::Tester::LogWriter::Filename->new({
    filename_template => $template,
  });

  $writer->write("logged line\n");

  my $expected_file = "$dir/test-$$.log";
  ok(-f $expected_file, "log file was created");

  open my $fh, '<', $expected_file or die "can't read $expected_file: $!";
  my $content = do { local $/; <$fh> };
  is($content, "logged line\n", "log file has expected content");
};

subtest "Logger coercion - coderef" => sub {
  require JMAP::Tester::Logger::HTTP;

  my @lines;
  my $logger = JMAP::Tester::Logger::HTTP->new({
    writer => sub { push @lines, $_[0] },
  });

  isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Code');
  $logger->write("test line");
  is_deeply(\@lines, ["test line"], "coderef writer works through logger");
};

subtest "Logger coercion - handle" => sub {
  require JMAP::Tester::Logger::HTTP;

  my $output = '';
  open my $fh, '>', \$output or die $!;

  my $logger = JMAP::Tester::Logger::HTTP->new({ writer => $fh });

  isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Handle');
  $logger->write("handle test");
  is($output, "handle test", "handle writer works through logger");
};

subtest "Logger coercion - undef scalar ref" => sub {
  require JMAP::Tester::Logger::HTTP;

  my $logger = JMAP::Tester::Logger::HTTP->new({ writer => \undef });

  isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Code');
  # Should not die - it's a no-op writer
  $logger->write("this goes nowhere");
  pass("undef scalar ref writer is a no-op");
};

subtest "Logger coercion - filename string" => sub {
  require JMAP::Tester::Logger::HTTP;
  require File::Temp;

  my $dir = File::Temp::tempdir(CLEANUP => 1);
  my $template = "$dir/logger-{PID}.log";

  my $logger = JMAP::Tester::Logger::HTTP->new({ writer => $template });

  isa_ok($logger->writer, 'JMAP::Tester::LogWriter::Filename');
};

subtest "UA::LWP cookie and header methods" => sub {
  require JMAP::Tester::UA::LWP;

  my $ua = JMAP::Tester::UA::LWP->new;

  # set_default_header / get_default_header
  $ua->set_default_header('X-Test-Header', 'test-value');
  is(
    $ua->get_default_header('X-Test-Header'),
    'test-value',
    "get/set default header round-trips",
  );

  # set_cookie
  $ua->set_cookie({
    api_uri => 'https://example.com/api/',
    name    => 'session',
    value   => 'abc123',
  });

  # scan_cookies
  my @cookies;
  $ua->scan_cookies(sub {
    my @args = @_;
    push @cookies, $args[1]; # cookie name is second arg
  });

  ok(
    (grep { $_ eq 'session' } @cookies),
    "set_cookie + scan_cookies round-trip",
  );

  # set_cookie missing required field
  for my $field (qw(api_uri name value)) {
    my %args = (api_uri => 'https://x.com/', name => 'n', value => 'v');
    delete $args{$field};
    my $err = exception { $ua->set_cookie(\%args) };
    like($err, qr/can't set_cookie without $field/, "set_cookie requires $field");
  }
};

subtest "Logger::Null methods" => sub {
  require JMAP::Tester::Logger::Null;

  # Logger::Null consumes Logger role which requires writer, but Null
  # doesn't use it. We supply a no-op writer.
  my $null = JMAP::Tester::Logger::Null->new({ writer => sub {} });

  # All of these should be no-ops and not die
  for my $method (qw(
    log_jmap_request     log_jmap_response
    log_misc_request     log_misc_response
    log_upload_request   log_upload_response
    log_download_request log_download_response
  )) {
    my $ok = eval { $null->$method(); 1 };
    ok($ok, "$method is callable and doesn't die");
  }
};

done_testing;
