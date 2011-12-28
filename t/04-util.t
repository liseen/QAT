use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../inc";
use lib "$FindBin::Bin/../lib";

use QAT::Util;

use Test::More;
plan tests => 3;

my $res = QAT::Util::do_http_request({
        url => 'http://www.qunar.com/'
    });

ok($res->is_success, 'request okay');
is($res->code, 200, 'http code okay');
is($res->header('Content-Type'), 'text/html', 'content-type');


