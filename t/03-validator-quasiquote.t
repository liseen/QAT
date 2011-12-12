use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../inc";
use lib "$FindBin::Bin/../lib";


use Test::Base;
use JSON::XS;

#use Smart::Comments;

use QAT::Validator::QuasiQuote;

use Test::More;
plan tests => 4;

my $data = { foo => 4};

is 1, 1, 'name';

my $foo;
[:validator|
    $data ~~ {
        foo: INT :to($foo)
    }
|]
is $foo, 4, 'foo eq 4';

my $foo2;
eval {
    [:validator|
        $data ~~ {
            foo2: STRING :to($foo2)
        }
    |]
};
if ($@) {
    ok $@, 'invalid ok';
}

is $foo2, undef, 'foo2 undef';


