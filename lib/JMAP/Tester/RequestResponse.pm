use v5.10.0;

package JMAP::Tester::RequestResponse;
use Moo;
with 'JMAP::Tester::Role::Result';

use JMAP::Tester::CallResponse;
use JMAP::Tester::CallResponseSet;

sub is_success { 1 }

has response => (
  is       => 'bare',
  reader   => '_response',
  required => 1,
);

sub BUILD {
  $_[0]->_index_setup;
}

# map names to index sets
# map CRS indices to index sets
sub _index_setup {
  my ($self) = @_;

  my $res = $self->_response;

  my $prev_cid;
  my $next_set_idx = 0;

  my %cid_indices;
  my @set_indices;

  for my $i (0 .. $#$res) {
    my $cid = $res->[$i][2];
    Carp::confess("no client_id for call response in position $i")
      unless defined $cid;

    if (defined $prev_cid && $prev_cid ne $cid) {
      # We're transition from cid1 to cid2. -- rjbs, 2016-04-08
      Carp::confess("client_id <$cid> appears in non-contiguous positions")
        if $cid_indices{$cid};

      $next_set_idx++;
    }

    push @{ $cid_indices{$cid} }, $i;
    push @{ $set_indices[ $next_set_idx ] }, $i;

    $prev_cid = $cid;
  }

  $self->_cid_indices(\%cid_indices);
  $self->_set_indices(\@set_indices);
}

has cid_indices => (is => 'bare', accessor => '_cid_indices');
has set_indices => (is => 'bare', accessor => '_set_indices');

sub call_response {
  my ($self, $n) = @_;
  return unless my $triple = $self->_response->[$n];
  return JMAP::Tester::CallResponse->new($triple);
}

sub crs {
  my ($self, $n) = @_;
  $self->call_response_set($n);
}

sub call_response_set {
  my ($self, $n) = @_;

  return unless my $indices = $self->_set_indices->[$n];
  my @triples = @{ $self->_response }[ @$indices ];
  return JMAP::Tester::CallResponseSet->new({
    responses => [ map {; JMAP::Tester::CallResponse->new($_) } @triples ],
  });
}

sub n_call_response_sets {
  my ($self, $n) = @_;

  return unless my @set_indices = @{ $self->_set_indices };
  if (defined $n and @set_indices != $n) {
    Carp::confess("expected $n call response sets but got " . @set_indices)
  }

  my $res = $self->_response;

  my @sets;
  for my $i_set (@set_indices) {
    push @sets, JMAP::Tester::CallResponseSet->new({
      responses => [
        map {; JMAP::Tester::CallResponse->new($_) } @{$res}[ @$i_set ]
      ],
    });
  }

  return @sets;
}

sub call_response_set_by_cid {
  my ($self, $cid) = @_;

  return unless my $indices = $self->_cid_indices->{$cid};
  my @triples = @{ $self->_response }[ @$indices ];
  return JMAP::Tester::CallResponseSet->new({
    responses => [ map {; JMAP::Tester::CallResponse->new($_) } @triples ],
  });
}

1;
