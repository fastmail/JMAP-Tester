use v5.10.0;
use warnings;

package JMAP::Tester::UA::Async;

use Moo;
with 'JMAP::Tester::Role::UA';

use Future;

has client => (
  is   => 'ro',
  required => 1,
);

sub set_cookie {
  my ($self, $arg) = @_;

  for (qw(api_uri name value)) {
    Carp::confess("can't set_cookie without $_") unless $arg->{$_};
  }

  my $uri = URI->new($arg->{api_uri});

  $self->client->cookie_jar->set_cookie(
    1,
    $arg->{name},
    $arg->{value},
    '/',
    $arg->{domain} // $uri->host,
    $uri->port,
    0,
    ($uri->port == 443 ? 1 : 0),
    86400,
    0,
    $arg->{rest} || {},
  );
}

sub request {
  my ($self, $tester, $req, $log_type, $log_extra) = @_;

  my $logger = $tester->_logger;

  my $log_method = "log_" . ($log_type // 'jmap') . '_request';
  $self->ua->set_my_handler(request_send => sub {
    my ($req) = @_;
    $logger->$log_method({
      ($log_extra ? %$log_extra : ()),
      http_request => $req,
    });
    return;
  });

  my $http_res = $self->lwp->request($post);

  # Clear our handler, or it will get called for
  # any http request our ua makes!
  $self->ua->set_my_handler(request_send => undef);

  return Future->done($http_res);
}

no Moo;
1;
