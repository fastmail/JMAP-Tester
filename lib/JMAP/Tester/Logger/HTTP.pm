use 5.14.0;
package JMAP::Tester::Logger::HTTP;

use Moo;
with 'JMAP::Tester::Logger';

sub log_jmap_request {
  my ($self, $arg) = @_;

  state $i;
  $i++;

  $self->write("=== BEGIN JMAP HTTP REQUEST $i ===");
  $self->write( $arg->{http_request}->as_string );
  $self->write("=== END JMAP HTTP REQUEST $i ===");
  return;
}

sub log_jmap_response {
  my ($self, $arg) = @_;

  state $i;
  $i++;

  $self->write("=== BEGIN JMAP HTTP RESPONSE $i ===");
  $self->write( $arg->{http_response}->as_string );
  $self->write("=== END JMAP HTTP RESPONSE $i ===");
  return;
}

1;
