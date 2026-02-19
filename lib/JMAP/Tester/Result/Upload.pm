use v5.20.0;

package JMAP::Tester::Result::Upload;
# ABSTRACT: what you get when you upload a blob

use Moo;
with 'JMAP::Tester::Role::HTTPResult';

use experimental 'signatures';

use namespace::clean;

=head1 OVERVIEW

A JMAP::Tester::Result::Upload object represents the successful upload of a
JMAP blob.  It is a successful L<JMAP::Tester::Role::HTTPResult>, meaning it
has a C<http_response> method that returns an L<HTTP::Response> object.

=method blob_id

The blobId of the blob from the JMAP server.

=method blobId

An alias for C<blob_id> above.

=method type

The media type of the file (as specified in RFC6838, section 4.2) as set in the
Content-Type header of the upload HTTP request.

=method size

The size of the file in octets.

=cut

sub is_success { 1 }

has payload => (
  is => 'ro',
);

sub blob_id ($self) { $self->payload->{blobId}  }
sub blobId  ($self) { $self->payload->{blobId}  }
sub type    ($self) { $self->payload->{type}    }
sub size    ($self) { $self->payload->{size}    }

1;
