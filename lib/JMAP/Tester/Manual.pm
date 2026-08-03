package JMAP::Tester::Manual;
# ABSTRACT: how to use JMAP::Tester

=head1 OVERVIEW

JMAP::Tester is a simple JMAP client designed for testing, although it can
certainly be used outside of tests.  It's meant to be easy to use without a lot
of training, but it's not so simple that you don't need a little bit of
up-front knowledge.  This document is meant to give a high-level overview of
how to use it, with links to more detailed information as needed.  Quite
possibly, you won't need to click even one of them.

=head2 Return types and asynchrony

When using a JMAP::Tester, you'll need to know whether it was configured to run
synchronously or asynchronously.  You can check the result of calling
C<< L<JMAP::Tester/should_return_futures> >>, but really you want to know this
while writing your code, so just make sure you pay attention to how the object
was constructed.  If your tester returns futures, then its async methods return
Future objects and can be called with C<await>.  Otherwise, they will block and
return whatever the future would have resolved to.

The default behavior is to I<not> return futures, as most test suites are
synchronous.

Methods generally return an object that does the
L<HTTPResult|JMAP::Tester::Role::HTTPResult> role, which has just a few
important methods:

=for :list
* C<is_success>, which returns true for a successful HTTP response and false otherwise
* C<http_response>, which returns the L<HTTP::Response> object for the result
* C<response_payload>, which returns the HTTP response as a string

=head2 Authentication and session

JMAP does not specify authentication, so authenticating your tester is up to
you.  Most often, you do that by setting a default header on the tester's user
agent, like this:

  my $tester = JMAP::Tester->new( ... );
  $tester->ua->set_default_header(Authorization => 'Bearer 1234');

This is a pretty broad brush, but for testing your local test system, generally
fine.

The other thing associated with authentication is your JMAP session, which
describes your account's capabilities and HTTP endpoints.  The session object
is generally represented as a L<JMAP::Tester::Result::Auth> object, which has
one useful method: C<client_session>, which returns the decoded JSON structure
of the session.

There are a few methods for dealing with the session:

=for :list
* C<< L<JMAP::Tester/get_client_session> >>, an async method that fetches and
returns the session object; on success, it returns an Auth object
* C<< L<JMAP::Tester/update_client_session> >>, an async method that gets the
client session, uses it to reconfigure the tester (if necessary), and returns
the Auth object

=head2 API requests

The most common thing you'll do with a tester is probably make API requests.
Those are the ones defined in L<RFC 8620
§3.1|https://datatracker.ietf.org/doc/html/rfc8620#section-3.1> -- the ones
with C<methodCalls>, where you do most of the work of JMAP.

You call it like this:

  my $res = $tester->request({
    using       => [ 'urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:mail' ],
    methodCalls => [ [ 'Some/method', { ... }, 'a' ], ... ],
  });

If you trust the client's C<default_using>, provided during creation, you can
skip the outer hashref and just provide an arrayref, which will be used as the
C<methodCalls> value.  Each entry in that arrayref is itself an arrayref that
becomes the C<Invocation> (in RFC 8620 terms) that's passed to the remote API.
If you don't include a method call id, the third element in the array, one will
be generated for you.

C<request> is an async method, and on success returns a
L<Response|JMAP::Tester::Response> object.  Since a I<lot> of testing your JMAP
server involves inspecting API responses, it's important to know the interface!
First, some jargon:  a I<sentence> is one entry in the C<methodResponses>
array; a I<paragraph> is a group of sequential sentences all sharing the same
method call id.  The first element in a sentence is its I<name>.  Almost
always, you'll be working with the sentences in a response, usually looked up
by name.

Here are the most important methods on a Response:

=for :list
* C<sentence($n)> returns the I<n>th sentence in the response (or dies if out
of bounds)
* C<sentence_named($name)> returns the sentence with this name (or dies if
there isn't exactly one with that name)
* C<single_sentence($name)> dies unless there is exactly one sentence in the
response; if C<$name> is given, the method dies unless the sentence has that
name; if it doesn't die, it returns that sentence.
* C<as_pairs> and C<as_triples> return arrayrefs where each element is a 2- or
3-element arrayref of the name, arguments, and (maybe) client id of each
sentence -- in other words, a plain structure representing the method response
* C<as_stripped_pairs> and C<as_stripped_triples> return the same, but with
L<JSON::Typist> data tripped from the arguments

L<Sentence|JMAP::Tester::Response::Sentence> objects have these useful methods:

=for :list
* C<name> returns the sentence name
* C<arguments> returns the sentence arguments
* C<client_id> returns the method call id
* C<as_pair>, C<as_triple>, C<as_stripped_pair>, and C<as_stripped_triple>
behave like the similarly-named methods on a Response, but just return the
arrayref representing this sentence
* C<as_set> returns a new L<Set|JMAP::Tester::Response::Sentence::Set> object,
with extra methods for testing the response to C</set>-style methods

A "Set" sentence has all the methods of a normal sentence as well as:

=for :list
* C<new_state> and C<old_state>: return the new and old state
* C<created>: returns the C<created> argument, or an empty hashref if null
* C<created_id($creation_id)>: returns the C<id> for the object created for
that creation id
* C<updated>: returns the C<updated> argument, or an empty hashref if null
* C<created_ids>, C<updated_ids>, C<destroyed_ids>: return the ids of objects
created, updated, or destroyed
* C<create_errors>, C<update_errors>, C<destroy_errors>: return the errors with
their respective operations, or an empty hashref if none
* C<not_created_ids>, C<not_updated_ids>, C<not_destroyed_ids>: return the ids
of objects not created, not updated, or not destroyed; in other words, the keys
of the hashrefs returned by the error methods above

There are also a few useful assertion-making methods to know.  These will throw
aborts (L<see below|/Diagnostics and logging>) if the condition they assert
doesn't hold true:

=for :list
* C<< $result->assert_successful >>: the result must be a success
(C<is_success> is true)
* C<< $result->assert_successful_set($name) >>: the result must be an API
request result with a sentence named C<$name>, which must be a C</set> method,
and it must be reporting zero errors (like C<notCreated> etc.)
* C<< $result->assert_single_successful_set($name) >>: just like the above, but
there must be only one sentence in the response; C<$name> can be omitted to
allow any C</set>
* C<< $set->assert_no_errors >>: on a Set sentence, this asserts that there
were no errors in any of its operations

=head2 Uploads and downloads

Testing blobs might require that you perform JMAP upload or download requests.
For these, the C<< L<JMAP::Tester/upload> >> and C<< L<JMAP::Tester/download>
>> methods exist.

C<upload> takes as its argument a hashref of upload properties and on success
returns an L<Upload|JMAP::Tester::Result::Upload> object.  The argument hashref
must contain:

  accountId - the account for which we're uploading (no default)
  type      - the content-type we want to provide to the server
  blob      - the data to upload. Must be a reference to a string

C<download> takes as its argument a hashref of download properties and on
success returns a L<Download|JMAP::Tester::Result::Download> object.  The
argument hashref must contain:

  blobId    - the blob to download (no default)
  accountId - the account for which we're downloading (no default)
  type      - the content-type we want the server to provide back (no default)
  name      - the name we want the server to provide back (default: "download")

=head2 Other HTTP requests

Sometimes, you may need to make a custom HTTP request with the same underlying
user agent as your tester uses.  This might be to interact with a custom
authentication mechanism, to access custom endpoints, or just to make very,
very specifically crafted requests.  For this reason, C<http_request> exists.
It's an async method that takes an L<HTTP::Request> object as its argument and
returns an L<HTTP::Response>.  Remember when you make this call that the
default headers you may have set up for auth will be applied!

=head2 Diagnostics and logging

Many of JMAP::Tester's failures are L<Test::Abortable> exceptions ("aborts")
that can terminate subtests without terminating the whole test program.  They
provide useful diagnostics on failure, so learning and using the JMAP::Tester
methods that die on unexpected results can save you time later.

Further, JMAP::Tester has a generic request logging system.  It's subject to
significant change, but the important thing to know is that if you set the
C<JMAP_TESTER_LOGGER> environment variable to C<HTTP>, you'll end up with a
file in the current working directory with a name like F<jmap-tester-….log>
that contains the requests and responses made.

=cut

1;
