use v5.14.0;
package JMAP::Tester::Logger::HTTP;

use Moo;

use namespace::clean;

my %counter;

sub _log_generic {
  my ($self, $tester, $type, $thing) = @_;

  my $i = $counter{$type}++;
  my $ident = $tester->ident;
  $self->write("=== BEGIN \U$type\E $$.$i ($ident) ===\n");
  $self->write( $thing->as_string );
  $self->write("=== END \U$type\E $$.$i ($ident) ===\n");
  return;
}

for my $which (qw(jmap misc upload download)) {
  for my $what (qw(request response)) {
    my $method = "log_${which}_${what}";
    no strict 'refs';
    *$method = sub {
      my ($self, $tester, $arg) = @_;
      $self->_log_generic($tester, "$which $what", $arg->{"http_$what"});
    }
  }
}

with 'JMAP::Tester::Logger';

1;
