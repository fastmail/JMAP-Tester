use v5.10.0;
use strict;

package JMAP::Tester::Result::Failure;
use Moo;
with 'JMAP::Tester::Role::Result';

sub is_success { 0 }

1;
