use v5.10.0;
package JMAP::Tester::CallResponseSet;
use Moo;

has responses => (reader => '_responses', required => 1);

sub responses { @{ $_[0]->_responses } }

1;
