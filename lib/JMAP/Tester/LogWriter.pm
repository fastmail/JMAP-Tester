package JMAP::Tester::LogWriter;

use Moo::Role;

requires 'write';

{
  package JMAP::Tester::LogWriter::Code;

  use Moo;
  with 'JMAP::Tester::LogWriter';
  has code => (is => 'ro', required => 1);
  sub write { $_[0]->code->($_[1]) }
}

{
  package JMAP::Tester::LogWriter::Handle;

  use Moo;
  with 'JMAP::Tester::LogWriter';
  has handle => (is => 'ro', required => 1);
  sub write { $_[0]->handle->print($_[1]) }
}

{
  package JMAP::Tester::LogWriter::Filename;

  use Moo;
  with 'JMAP::Tester::LogWriter';
  has filename_template => (
    is       => 'ro',
    default => 'jmap-tester-{T}-{PID}.log',
  );

  has _handle => (is => 'rw');
  has _pid => (is => 'rw', init_arg => undef, default => -1);

  sub write { $_[0]->_ensure_handle->print($_[1]) }

  sub _ensure_handle {
    my ($self) = @_;
    return $self->_handle if $self->_pid == $$;

    my $fn = $self->filename_template =~ s/\{T\}/$^T/gr =~ s/\{PID\}/$$/gr;
    open my $fh, '>>', $fn or Carp::confess("can't open $fn for writing: $!");

    $fh->autoflush(1);

    $self->_handle($fh);
    $self->_pid($$);
    return $fh;
  }
}

1;
