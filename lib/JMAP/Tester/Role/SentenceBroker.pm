package JMAP::Tester::Role::SentenceBroker;

use Moo::Role;

requires 'client_ids_for_items';
requires 'sentence_for_item';
requires 'paragraph_for_items';

requires 'strip_json_types';

requires 'abort';

1;
