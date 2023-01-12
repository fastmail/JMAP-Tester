use v5.14.0;
package JMAP::Tester::Logger::HTTP;

use Moo;

use namespace::clean;

my %counter;

sub _log_generic {
  my ($self, $type, $thing) = @_;

  my $i = $counter{$type}++;
  $self->write("=== BEGIN \U$type\E $$.$i ===\n");
  $self->write( $thing->as_string );
  $self->write("=== END \U$type\E $$.$i ===\n");
  return;
}

for my $which (qw(jmap misc upload download)) {
  for my $what (qw(request response)) {
    my $method = "log_${which}_${what}";
    no strict 'refs';
    *$method = sub {
      my ($self, $arg) = @_;
      $self->_log_generic("$which $what", $arg->{"http_$what"});
    }
  }
}

with 'JMAP::Tester::Logger';

1;
