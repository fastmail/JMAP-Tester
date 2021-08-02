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

sub scan_cookies {
  my ($self, $callback) = @_;
  return $self->client->cookie_jar->scan($callback);
}

has _default_headers => (
  is => 'ro',
  default => sub {  {}  },
);

sub set_default_header {
  my ($self, $name, $value) = @_;

  if (defined $value) {
    $self->_default_headers->{$name} = $value;
  } else {
    delete $self->_default_headers->{$name};
  }

  return;
}

sub request {
  my ($self, $tester, $req, $log_type, $log_extra) = @_;

  my $dh = $self->_default_headers;
  for my $h (keys %$dh) {
    $req->header($h => $dh->{$h}) unless defined $req->header($h);
  }

  my $logger = $tester->_logger;

  my $log_method = "log_" . ($log_type // 'jmap') . '_request';

  return $self->client->do_request(
    request => $req,
    on_ready => sub {
      # This fires just before the request is written to the socket, just
      # like how LWP::UserAgent logs the request before actually sending
      # it
      my $log_method = "log_" . ($log_type // 'jmap') . '_request';

      $tester->_logger->$log_method({
        ($log_extra ? %$log_extra : ()),
        http_request => $req,
      });

      return Future->done;
    },
  );
}

no Moo;
1;
