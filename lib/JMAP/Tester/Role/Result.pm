use v5.10.0;
use warnings;
package JMAP::Tester::Role::Result;
# ABSTRACT: the kind of thing that you get back for a request

use Moo::Role;

requires 'is_success';

1;
