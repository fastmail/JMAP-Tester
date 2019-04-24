use v5.10.0;
use warnings;

package JMAP::Tester::Role::UA;

use Moo::Role;

# $ua->request( HTTP::Request ) returns Future( HTTP::Response )
requires qw( request );

# Is this a terrible idea?
requires qw( set_cookie );

no Moo::Role;
1;
