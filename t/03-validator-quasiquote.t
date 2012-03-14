use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../inc";
use lib "$FindBin::Bin/../lib";

use URI::Escape;
use QAT::Validator::QuasiQuote;

use Smart::Comments;
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

my $c = "中国";
my $url = [:uriescape|
    http://www.baidu.com/c=$c&b=aaa
|];

is $url, 'http://www.baidu.com/c=%E4%B8%AD%E5%9B%BD&b=aaa', 'uri escape';
### $url
