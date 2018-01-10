use v5.14.10;
use warnings;

use Test::More;
use JMAP::Tester::Util;

sub true { \1 }

sub resolve_ok {
  my ($pointer, $want, $desc) = @_;
  $desc //= qq{resolved q<$pointer> successfully};

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  our $Test_Struct;

  my ($struct, $error) = JMAP::Tester::Util::resolve_modified_jpointer(
    $pointer,
    $Test_Struct,
  );

  diag "error was: $error"
    if ! is_deeply($struct, $want, $desc) && $error;
}

sub error_ok {
  my ($pointer, $want, $desc) = @_;
  $desc //= $want;

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  our $Test_Struct;

  my (undef, $error) = JMAP::Tester::Util::resolve_modified_jpointer(
    $pointer,
    $Test_Struct,
  );

  is($error, $_[1], $_[1]);
}

subtest "examples from RFC 6901" => sub {
  local our $Test_Struct = {
    "foo"  => ["bar", "baz"],
    ""     => 0,
    "a/b"  => 1,
    "c%d"  => 2,
    "e^f"  => 3,
    "g|h"  => 4,
    "i\\j" => 5,
    "k\"l" => 6,
    " "    => 7,
    "m~n"  => 8,
  };

  my %expect = (
    ""        =>  $Test_Struct,
    "/foo"    =>  ["bar", "baz"],
    "/foo/0"  =>  "bar",
    "/"       =>  0,
    "/a~1b"   =>  1,
    "/c%d"    =>  2,
    "/e^f"    =>  3,
    "/g|h"    =>  4,
    "/i\\j"   =>  5,
    "/k\"l"   =>  6,
    "/ "      =>  7,
    "/m~0n"   =>  8,
  );

  for my $path (sort keys %expect) {
    resolve_ok($path, $expect{$path});
  }
};

subtest "simple use of asterisk on array" => sub {
  # JMAP-style use of asterisk
  local our $Test_Struct = {
    bar => [
      { x => 1 },
      { x => 0 },
      { x => undef },
      { x => 10 },
    ],
  };

  resolve_ok('/bar/*/x', [ 1, 0, undef, 10 ]);
};

subtest "simple errors and complex success" => sub {
  local our $Test_Struct = {
    xy => [
      { x => 1 },
      { y => 2 },
    ],
    stats   => {
      str => 10, dex => 10, con => 11,
      int => 14, wis => 12, cha => 12,
    },
    allarr  => [ [ 2, 4 ], [ 6, 8 ] ],
    somearr => [ 2, [ 4, 6 ], { we => [ 8 ] } ],
    boolean => true,
  };

  resolve_ok("/allarr/*/0", [ 2, 6 ]);
  resolve_ok("/allarr/*",   [ 2, 4, 6, 8 ]);

  resolve_ok("/somearr/*",  [ 2, 4, 6, { we => [ 8 ] } ]);

  resolve_ok("/boolean",    true);

  error_ok(
    "/boolean/",
    "can't descend into non-Array, non-Object at /boolean/",
  );

  error_ok("!", "pointer begins with non-slash");
  error_ok(undef, "no pointer given");
  error_ok(
    "/stats/dex/10",
    "can't descend into non-Array, non-Object at /stats/dex/10",
  );

  error_ok(
    "/stats/*/x",
    "property does not exist at /stats/*",
  );

  error_ok(
    "/xy/*/y",
    "property does not exist at /xy/*/y with asterisk indexing 0",
  );

  error_ok(
    "/xy/*/x",
    "property does not exist at /xy/*/x with asterisk indexing 1",
  );
};

done_testing;
