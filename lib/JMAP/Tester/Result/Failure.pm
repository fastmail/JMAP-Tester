use v5.10.0;
use strict;

package JMAP::Tester::Result::Failure;
# ABSTRACT: what you get when your JMAP request utterly fails

use Moo;
with 'JMAP::Tester::Role::Result';

sub is_success { 0 }

1;
