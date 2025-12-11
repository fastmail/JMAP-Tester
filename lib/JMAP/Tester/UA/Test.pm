use v5.14.0;
use warnings;

package JMAP::Tester::UA::Test;

use Moo;
with 'JMAP::Tester::Role::UA';

use Carp ();
use Future;
use HTTP::Response;

has request_handler => (
  is  => 'ro',
  required => 1,
  default  => sub {
    return sub {
      return HTTP::Response->new(200, "Reply meaningless");
    };
  },
);

has _transactions => (
  is => 'rw',
  init_arg => undef,
  lazy     => 1,
  default  => sub {  []  },
  clearer  => 'clear_transactions',
);

sub transactions {
  my ($self) = @_;
  return $self->_transactions->@*;
}

sub request {
  my ($self, $tester, $req, $log_type, $log_extra) = @_;

  my $res = $self->request_handler->(@_);

  my $logger = $tester->_logger;
  my $log_method = "log_" . ($log_type // 'jmap') . '_request';

  $logger->$log_method(
    $tester,
    {
      ($log_extra ? %$log_extra : ()),
      http_request => $req,
    }
  );

  push $self->_transactions->@*, {
    request  => $req,
    response => $res,
  };

  return Future->done($res);
}

sub set_cookie         { Carp::confess("set_cookie not implemented") }
sub scan_cookies       { Carp::confess("scan_cookies not implemented") }
sub get_default_header { Carp::confess("get_default_header not implemented") }
sub set_default_header { Carp::confess("set_default_header not implemented") }

no Moo;
1;
