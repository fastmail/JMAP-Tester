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
  my $next_set_idx = 0;

  my %cid_indices;
  my @set_indices;

  for my $i (0 .. $#$res) {
    my $cid = $res->[$i][2];
    Carp::confess("no client_id for response sentence in position $i")
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

# I should just have cid-to-paragraph and paragraph-to-sentence.
has cid_indices => (is => 'bare', accessor => '_cid_indices');
has set_indices => (is => 'bare', accessor => '_set_indices');

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

  return unless my $indices = $self->_set_indices->[$n];
  my @triples = @{ $self->_struct }[ @$indices ];
  return JMAP::Tester::Response::Paragraph->new({
    sentences => [ map {; JMAP::Tester::Response::Sentence->new($_) } @triples ],
  });
}

sub assert_n_paragraphs {
  my ($self, $n) = @_;

  return unless my @set_indices = @{ $self->_set_indices };
  if (defined $n and @set_indices != $n) {
    Carp::confess("expected $n paragraphs but got " . @set_indices)
  }

  my $res = $self->_struct;

  my @sets;
  for my $i_set (@set_indices) {
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
