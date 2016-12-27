package JMAP::Tester::Logger::Null;

use Moo;
with 'JMAP::Tester::Logger';

sub log_jmap_request  {}
sub log_jmap_response {}

sub log_upload_request  {}
sub log_upload_response {}

sub log_download_request  {}
sub log_download_response {}

1;
