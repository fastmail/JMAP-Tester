use strict;
use warnings;

use JMAP::Tester::Sugar '-all';

use Test::Deep ':v1';
use Test::Deep::JType;
use Test::More;

jcmp_deeply(
  jset(Email => { create => [ { subject => "Hi" }, { subject => "Bye" } ] }),
  [ 'Email/set', { create => {
    0 => { subject => "Hi" },
    1 => { subject => "Bye" },
  } } ],
  "multi-object jset create",
);

jcmp_deeply(
  jset(Email => { create => { subject => "Hi" } }),
  [ 'Email/set', { create => { 0 => { subject => "Hi" } } } ],
  "single-object jset create",
);

jcmp_deeply(
  jcreate(Email => [ { subject => "Hi" }, { subject => "Bye" } ]),
  [ 'Email/set', { create => {
    0 => { subject => "Hi" },
    1 => { subject => "Bye" },
  } } ],
  "multi-object jcreate",
);

jcmp_deeply(
  jcreate(Email => { subject => "Hi" }),
  [ 'Email/set', { create => { 0 => { subject => "Hi" } } } ],
  "single-object jcreate",
);

done_testing;
