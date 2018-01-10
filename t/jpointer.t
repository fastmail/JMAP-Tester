use v5.14.10;
use warnings;

use Test::More;
use JMAP::Tester::Util;

subtest "examples from RFC 6901" => sub {
  my $struct = {
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
    ""        =>  $struct,
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
    my $result = JMAP::Tester::Util::resolve_modified_jpointer($path, $struct);
    is_deeply($result, $expect{$path}, "resolved $path");
  }
};

subtest "simple use of asterisk on array" => sub {
  # JMAP-style use of asterisk
  my $struct = {
    bar => [
      { x => 1 },
      { x => 0 },
      { x => undef },
      { x => 10 },
    ],
  };

  my $result = JMAP::Tester::Util::resolve_modified_jpointer(
    '/bar/*/x',
    $struct,
  );

  is_deeply($result, [ 1, 0, undef, 10 ], "we star mapped");
};

done_testing;
