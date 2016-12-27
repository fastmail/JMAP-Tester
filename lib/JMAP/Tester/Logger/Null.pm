package JMAP::Tester::Logger::Null;

use Moo;
with 'JMAP::Tester::Logger';

sub log_jmap_request  {}
sub log_jmap_response {}

1;
