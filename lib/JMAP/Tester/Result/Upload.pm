use v5.10.0;
use strict;

package JMAP::Tester::Result::Upload;
# ABSTRACT: what you get when you upload a blob

use Moo;
with 'JMAP::Tester::Role::HTTPResult';

use namespace::clean;

=head1 OVERVIEW

This is what you get when you upload!  It's got an C<is_success> method.  It
returns true. It also has:

=method blob_id

The blobId of the blob from the JMAP server.

=method blobId

An alias for C<blob_id> above.

=method type

The media type of the file (as specified in RFC6838, section 4.2) as 
set in the Content-Type header of the upload HTTP request.

=method size

The size of the file in octets.

=cut

sub is_success { 1 }

has payload => (
  is => 'ro',
);

sub blob_id { $_[0]->payload->{blobId}  }
sub blobId  { $_[0]->payload->{blobId}  }
sub type    { $_[0]->payload->{type}    }
sub size    { $_[0]->payload->{size}    }

1;
