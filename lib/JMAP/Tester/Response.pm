use v5.10.0;

package JMAP::Tester::Response;
use Moo;
with 'JMAP::Tester::Role::Result';

use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;

sub is_success { 1 }

has struct => (
  is       => 'bare',
  reader   => '_struct',
  required => 1,
);

sub BUILD {
  $_[0]->_index_setup;
}

# map names to index sets
# map CRS indices to index sets
sub _index_setup {
  my ($self) = @_;

  my $res = $self->_struct;

  my $prev_cid;
  my $next_para_idx = 0;

  my %cid_indices;
  my @para_indices;

  for my $i (0 .. $#$res) {
    my $cid = $res->[$i][2];

    unless (defined $cid) {
      Carp::cluck("no client_id for response sentence in position $i");
      next;
    }

    if (defined $prev_cid && $prev_cid ne $cid) {
      # We're transition from cid1 to cid2. -- rjbs, 2016-04-08
      Carp::cluck("client_id <$cid> appears in non-contiguous positions")
        if $cid_indices{$cid};

      $next_para_idx++;
    }

    push @{ $cid_indices{$cid} }, $i;
    push @{ $para_indices[ $next_para_idx ] }, $i;

    $prev_cid = $cid;
  }

  $self->_cid_indices(\%cid_indices);
  $self->_para_indices(\@para_indices);
}

# The reason we don't have cid-to-para and para-to-lines is that in the event
# that one cid appears in non-contiguous positions, we want to allow it, even
# though it's garbage.  -- rjbs, 2016-04-11
has cid_indices  => (is => 'bare', accessor => '_cid_indices');
has para_indices => (is => 'bare', accessor => '_para_indices');

sub sentence {
  my ($self, $n) = @_;
  return unless my $triple = $self->_struct->[$n];
  return JMAP::Tester::Response::Sentence->new($triple);
}

sub single_sentence {
  my ($self) = @_;

  my @triples = @{ $self->_struct };
  unless (@triples == 1) {
    Carp::confess(
      sprint("single_sentence called but there are %i sentences", 0+@triples)
    );
  }

  return JMAP::Tester::Response::Sentence->new($triples[0]);
}

sub paragraph {
  my ($self, $n) = @_;

  return unless my $indices = $self->_para_indices->[$n];
  my @triples = @{ $self->_struct }[ @$indices ];
  return JMAP::Tester::Response::Paragraph->new({
    sentences => [ map {; JMAP::Tester::Response::Sentence->new($_) } @triples ],
  });
}

sub assert_n_paragraphs {
  my ($self, $n) = @_;

  return unless my @para_indices = @{ $self->_para_indices };
  if (defined $n and @para_indices != $n) {
    Carp::confess("expected $n paragraphs but got " . @para_indices)
  }

  my $res = $self->_struct;

  my @sets;
  for my $i_set (@para_indices) {
    push @sets, JMAP::Tester::Response::Paragraph->new({
      sentences => [
        map {; JMAP::Tester::Response::Sentence->new($_) } @{$res}[ @$i_set ]
      ],
    });
  }

  return @sets;
}

sub paragraph_by_client_id {
  my ($self, $cid) = @_;

  return unless my $indices = $self->_cid_indices->{$cid};
  my @triples = @{ $self->_struct }[ @$indices ];
  return JMAP::Tester::Response::Paragraph->new({
    sentences => [ map {; JMAP::Tester::Response::Sentence->new($_) } @triples ],
  });
}

sub as_struct {
  my ($self) = @_;

  return [
    map {; JMAP::Tester::Response::Sentence->new($_)->as_struct }
    @{ $self->_struct }
  ];
}

1;
