package JMAP::Tester::Logger;

use Moo::Role;

use Params::Util qw(_CODELIKE _HANDLE _SCALAR0);

has writer => (
  is  => 'ro',
  isa => sub {
    die "no writer provided" unless $_[0];
    die "writer provided can't be called as code" unless _CODELIKE($_[0]);
  },
  coerce   => sub {
    my $value = $_[0];
    return $value if _CODELIKE($value);
    if (_HANDLE($value)) { return sub { $value->print($_[0]); }; }
    if (_SCALAR0($value) && ! defined $$value) { return sub {} }
    if (defined $value && ! ref $value && length $value) {
      open(my $fh, ">>", $value)
        || Carp::confess("can't open file $value for writing: $!");

      return sub { $fh->print($_[0]) };
    }
    return $value;
  },
  required => 1,
);

sub write {
  my ($self, $string) = @_;
  $self->writer->( $string );
}

requires 'log_jmap_request';
requires 'log_jmap_response';

1;
