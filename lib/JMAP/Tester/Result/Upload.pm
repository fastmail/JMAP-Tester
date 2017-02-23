use v5.10.0;
use strict;

package JMAP::Tester::Result::Upload;
# ABSTRACT: what you get when you upload a blob

use Moo;
with 'JMAP::Tester::Role::Result';

use namespace::clean;

=head1 OVERVIEW

This is what you get when you upload!  It's got an C<is_success> method.  It
returns true.

=cut

sub is_success { 1 }

has payload => (
  is => 'ro',
);

sub blob_id { $_[0]->payload->{blobId}  }
sub blobId  { $_[0]->payload->{blobId}  }
sub type    { $_[0]->payload->{type}    }
sub size    { $_[0]->payload->{size}    }
sub expires { $_[0]->payload->{expires} }

1;
